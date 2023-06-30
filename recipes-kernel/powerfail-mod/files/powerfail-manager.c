// SPDX-License-Identifier: GPL-2.0-only
/*
 * Irma6R2 Power Fail Manager
 *
 * Copyright (C) 2023 iris-GmbH infrared & intelligent sensors
 *
 */

#include <linux/module.h>
#include <linux/gpio.h>
#include <linux/interrupt.h>
#include <linux/delay.h>
#include <linux/device.h>
#include <linux/sched.h>
#include <linux/irq_sim.h>

#define DEVICE_NAME "powerfail-manager"

// power good pin number
#define POWERSTATUS_PIN 97

static DEFINE_SPINLOCK(powergood_lock);
static struct task_struct *app_task = NULL;
static bool power_status;

struct irq_domain *irq_sim_domain;


/* --- DEVICE --- */
static void powerfail_release(struct device *dev)
{
    // Nothing to free, but device must have a release function
    // See Documentation/core-api/kobject.rst.
}

static struct device dev = {
    .init_name = DEVICE_NAME,
    .devt = MKDEV(0, 0), // automatic assignment
    .parent = NULL,
    .release = powerfail_release,
};
/* --- DEVICE END --- */

static bool task_alive(const struct task_struct *p)
{
    return (p != NULL) && pid_alive(p);
}

static irqreturn_t resume_after_power_failure(int irq, void *dev_id)
{
    int irq_sim;
    if (power_status) {
        return IRQ_HANDLED;
    }

    msleep(50); // app is paused for 50ms to survive a short power cutoff event

    spin_lock(&powergood_lock);
    power_status = true;
    spin_unlock(&powergood_lock);
    if (task_alive(app_task)) {
        dev_info(&dev, "Power failed! PID %d was paused for 50ms\n", app_task->pid);
        send_sig(SIGCONT, app_task, 1);
    }

    // trigger simulation IRQ
    irq_sim = irq_find_mapping(irq_sim_domain, 0);
    if (irq_sim){
       irq_set_irqchip_state(irq_sim, IRQCHIP_STATE_PENDING, true);
    }

    return IRQ_HANDLED;
}

static irqreturn_t powerfail_interrupt_handler(int irq, void *dev_id)
{
    if (!power_status) {
        return IRQ_HANDLED;
    }

    spin_lock(&powergood_lock);
    power_status = false;
    spin_unlock(&powergood_lock);

    if (task_alive(app_task)) {
        send_sig(SIGSTOP, app_task, 1);
    }

    return IRQ_WAKE_THREAD;
}

/* --- GPIO OPS --- */
static int powerfail_direction_input(struct gpio_chip *chip, unsigned offset);
static int powerfail_get_value(struct gpio_chip *chip, unsigned offset);
static int powerfail_to_irq(struct gpio_chip *chip, unsigned offset);
static int powerfail_request(struct gpio_chip *gc, unsigned int offset);
static void powerfail_free(struct gpio_chip *gc, unsigned int offset);

static struct gpio_chip powerfail_gc = {
    .label = "powerfail_gpio",
    .owner = THIS_MODULE,
    .ngpio = 1,
    .base = -1, // virtual base
    .can_sleep = false,
    .direction_input = powerfail_direction_input,
    .get = powerfail_get_value,
    .to_irq = powerfail_to_irq,
    .request = powerfail_request,
    .free = powerfail_free,
};

static int powerfail_direction_input(struct gpio_chip *chip, unsigned offset)
{
    return gpio_direction_input(POWERSTATUS_PIN);
}

static int powerfail_get_value(struct gpio_chip *chip, unsigned offset)
{
    return gpio_get_value(POWERSTATUS_PIN);
}

static int powerfail_to_irq(struct gpio_chip *chip, unsigned offset)
{
    return irq_create_mapping(irq_sim_domain, 0);
}

static int powerfail_request(struct gpio_chip *gc, unsigned int offset)
{
    int ret;
    if(task_alive(app_task)){
        return -EBUSY;
    }

    ret = gpio_direction_input(POWERSTATUS_PIN);
    if (ret < 0) {
        dev_err(&dev, "Failed to set GPIO pin direction: %d\n", ret);;
        return ret;
    }

    // set power status to enable IRQ handlers if power started in a bad state
    power_status = true;

    ret = gpio_to_irq(POWERSTATUS_PIN);
    if (ret < 0) {
        dev_err(&dev, "Failed to get IRQ: %d\n", ret);
        return ret;
    }

    ret = request_threaded_irq(ret, powerfail_interrupt_handler, resume_after_power_failure, 
        IRQF_TRIGGER_FALLING, "powerfail", &dev);
    if (ret < 0) {
        dev_err(&dev, "Failed to request IRQ: %d\n", ret);
        return ret;
    }

    app_task = current;

    dev_info(&dev, "Started Power Fail Manager for PID: %d\n", app_task->pid);
    return 0;
}

static void powerfail_free(struct gpio_chip *gc, unsigned int offset)
{
    free_irq(gpio_to_irq(POWERSTATUS_PIN), &dev);
    app_task = NULL;
}
/* --- GPIO OPS END --- */

static int __init powerfail_init(void)
{
    int ret;

    ret = device_register(&dev);
    if (ret < 0) {
        dev_err(&dev, "Failed to register device\n");
        return -ENODEV;
    }

    ret = gpio_request(POWERSTATUS_PIN, "powerstatus_gpio");
    if (ret < 0) {
        dev_err(&dev, "Failed to request power status pin\n");
        return ret;
    }

    ret = gpiochip_add_data(&powerfail_gc, NULL);
    if (ret < 0) {
        dev_err(&dev, "Failed to add gpio chip\n");
        return ret;
    }

    /* Create simulation IRQ domain to notify app in case of power failure */
    irq_sim_domain = devm_irq_domain_create_sim(&dev, NULL, powerfail_gc.ngpio);
    if (IS_ERR(irq_sim_domain)){
        dev_err(&dev, "Failed to add simulated IRQ\n");
        ret = PTR_ERR(irq_sim_domain);
        return ret;
    }

    dev_info(&dev, "Driver loaded\n");
    return ret;
}

static void __exit powerfail_exit(void)
{
    gpio_free(POWERSTATUS_PIN);
    gpiochip_remove(&powerfail_gc);
    device_unregister(&dev);
    pr_info("powerfail-manager: Driver unloaded\n");
}

module_init(powerfail_init);
module_exit(powerfail_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Ian Dannapel");
MODULE_DESCRIPTION("Power Fail Manager Module");
