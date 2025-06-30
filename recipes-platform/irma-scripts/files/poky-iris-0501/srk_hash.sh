#!/bin/sh
# Ported from:
#  - cst-3.4.1/add-ons/ahab_signature_block_parser/parse_sig_blk.py
#  - https://github.com/nxp-imx-support/nxp-cst-signer

usage(){
    name="$(basename "$0")"
    echo "### Extract and Calculate SRK Hash (sha256) ###"
    echo "       $name <Signed AHAB File> <Offset>"
    echo "  e.g. $name fitImage.signed     0x0"
    echo "    or $name flash.bin.signed    0x400"
}


if [ "$#" -ne 2 ]; then
    usage
    exit 1
fi

infile=$1
offset=$2

container_tag=$(hexdump -n 1 -s $((3+offset)) -e '"%#x"' "$infile")
container_version=$(hexdump -n 1 -s $((offset)) -e '"%#x"' "$infile")

if [ $((container_tag)) -ne $((0x87)) ]; then
    printf "ERROR: Invalid Container Tag: 0x%x\n" "$container_tag"
    exit 1
fi

if [ $((container_version)) -ne $((0x0)) ]; then
    printf "ERROR: Invalid Container Version: 0x%x\n" "$container_version"
    exit 1
fi

sig_blk_offset=$(hexdump -n 2 -s $((12+offset)) -e '1/2 "%#x"' "$infile")
sig_blk_offset=$((sig_blk_offset+offset))
sig_blk_table_off=$(hexdump -n 2 -s $((sig_blk_offset+6)) -e '1/2 "%#x"' "$infile")
srk_table_off=$((sig_blk_offset+sig_blk_table_off))
srk_tab_len=$(hexdump -n 2 -s $((srk_table_off+1)) -e '1/2 "%#x"' "$infile")

#printf "sig_blk_offset   : 0x%x\n" $sig_blk_offset
#printf "sig_blk_table_off: 0x%x\n" $sig_blk_table_off
#printf "srk_table_off    : 0x%x\n" $srk_table_off
#printf "srk_table_len    : 0x%x\n" $srk_tab_len

dd if="$infile" bs=1 count=$((srk_tab_len)) skip=$((srk_table_off)) 2> /dev/null | sha256sum | cut -d' ' -f1 | tr -d '\n'
