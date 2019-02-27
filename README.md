# Description

A rootless like jailbreak, some inspirtation was taken from jelbrekLib
Only experimental version, in bootstraps the minimum binaries and spawn Dropbear SSH

## TODO:

- AMFI Patch system wide(not via trustbin)
- / rw remount(lets see..)

## Support

- A12 devices

## Usage notes

- voucher_swap is used for 16K devices
- Binaries are located in: /var/containers/Bundle/iosbinpack64

All executables must have at least these two entitlements:

    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>platform-application</key>
        <true/>
        <key>com.apple.private.security.container-required</key>
        <false/>
    </dict>
    </plist>


Thanks to: Ian Beer, Brandon Azad, Jonathan Levin, Electra Team, IBSparkes, qwertyouriop, Sam Bingner, Sammy Guichelaar, pwn20wndstuff, jakejames, ProteasWang.


