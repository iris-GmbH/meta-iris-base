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
#include <linux/workqueue.h>
#include <linux/poll.h>
#include <linux/cdev.h>
#include <linux/device.h>


// power good pin number
#define GPIO_PIN 97

/* The name for our device, as it will appear in /proc/devices */
#define DEVICE_NAME "powerfail-manager"

static dev_t dev_number;
static struct cdev char_device;
static struct class *char_class;
static struct device *dev;

static DEFINE_SPINLOCK(powergood_lock);
static int app_pid;
static bool powergood;
static struct task_struct *app_task;
static struct work_struct powerfail_work;

/* --- FILE OPS --- */
static int powerfail_open(struct inode *, struct file *);
static int powerfail_release(struct inode *inodep, struct file *filep);

static const struct file_operations powerfail_fops = {
    .owner  = THIS_MODULE,
    .open   = powerfail_open,
    .release = powerfail_release,
};

static int powerfail_open(struct inode *inode, struct file *filp)
{
    if(get_pid_task(find_get_pid(app_pid), PIDTYPE_PID)){
        return -EBUSY;
    }
    app_pid = current->pid;
    dev_info(dev, "Started Power Fail Manager for PID: %d\n", app_pid);
    return 0;
}

static int powerfail_release(struct inode *inodep, struct file *filep) {
    app_pid = -1;
    app_task = NULL;
    return 0;
}
/* --- END FILE OPS --- */

static void resume_after_power_failure(struct work_struct *work) {

    msleep(50); // app is paused for 50ms to survive a short power cutoff event

    spin_lock(&powergood_lock);
    powergood = true;
    app_task = get_pid_task(find_get_pid(app_pid), PIDTYPE_PID);
    spin_unlock(&powergood_lock);

    if (app_task) {
        dev_info(dev, "Power failed! PID %d was paused for 50ms\n", app_pid);
        send_sig(SIGCONT, app_task, 1);
    }
}

static irqreturn_t powerfail_interrupt_handler(int irq, void *dev_id)
{
    if (!powergood) {
        return IRQ_HANDLED;
    } 

    spin_lock(&powergood_lock);
    powergood = false;
    app_task = get_pid_task(find_get_pid(app_pid), PIDTYPE_PID);
    spin_unlock(&powergood_lock);

    if (app_task) {
        send_sig(SIGSTOP, app_task, 1);
    }

    queue_work(system_long_wq, &powerfail_work);
    return IRQ_HANDLED;
}

static int __init powerfail_init(void)
{
    int ret;

    powergood = true;
    INIT_WORK(&powerfail_work, resume_after_power_failure);

    ret = alloc_chrdev_region(&dev_number, 0, 1, DEVICE_NAME);
    if (ret < 0) {
        pr_err("powerfail-manager: Failed to allocate char device region\n");
        goto gpio_err;
    }

    cdev_init(&char_device, &powerfail_fops);
    char_device.owner = THIS_MODULE;

    ret = cdev_add(&char_device, dev_number, 1);
    if (ret < 0) {
        pr_err("powerfail-manager: Failed to add char device\n");
        goto cdev_err;
    }

    char_class = class_create(THIS_MODULE, "power");
    if (IS_ERR(char_class)) {
        pr_err("powerfail-manager: Failed to create class\n");
        ret = PTR_ERR(char_class);
        goto class_err;
    }

    dev = device_create(char_class, NULL, dev_number, NULL, DEVICE_NAME);
    if (IS_ERR(dev)) {
        pr_err("powerfail-manager: Failed to create device\n");
        goto class_err;
    }

    ret = gpio_request(GPIO_PIN, "power_fail_gpio");
    if (ret < 0) {
        dev_err(dev, "Failed to request GPIO pin\n");
        goto gpio_err;
    }

    ret = gpio_direction_input(GPIO_PIN);
    if (ret < 0) {
        dev_err(dev, "Failed to set GPIO pin direction\n");
        goto gpio_err;
    }

    ret = gpio_to_irq(GPIO_PIN);
    if (ret < 0) {
        dev_err(dev, "Failed to get IRQ number\n");
        goto gpio_err;
    }

    ret = request_irq(ret, powerfail_interrupt_handler, IRQF_TRIGGER_FALLING, "powerfail", NULL);
    if (ret < 0) {
        dev_err(dev, "Failed to request IRQ\n");
        goto gpio_err;
    }

    dev_info(dev, "Driver loaded\n");
    return 0;

gpio_err:
    gpio_free(GPIO_PIN);
class_err:
    device_destroy(char_class, dev_number);
    class_destroy(char_class);
    cdev_del(&char_device);
cdev_err:
    unregister_chrdev_region(dev_number, 1);
    return ret;
}

static void __exit powerfail_exit(void)
{
    free_irq(gpio_to_irq(GPIO_PIN), NULL);
    gpio_free(GPIO_PIN);

    device_destroy(char_class, dev_number);
    class_destroy(char_class);
    cdev_del(&char_device);
    unregister_chrdev_region(dev_number, 1);

    pr_info("powerfail-manager: Driver unloaded\n");
}

module_init(powerfail_init);
module_exit(powerfail_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Ian Dannapel");
MODULE_DESCRIPTION("Power Fail Manager Module");
