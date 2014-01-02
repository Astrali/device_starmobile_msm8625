#!/system/bin/sh
# Copyright (c) 2012, Code Aurora Forum. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#     * Neither the name of Code Aurora Forum, Inc. nor the names of its
#       contributors may be used to endorse or promote products derived
#      from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
# ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
# Update USB serial number from persist storage if present, if not update
# with value passed from kernel command line, if none of these values are
# set then use the default value. This order is needed as for devices which
# do not have unique serial number.
# User needs to set unique usb serial number to persist.usb.serialno
#
serialno=`getprop persist.usb.serialno`
usb_mode=`getprop persist.sys.usb.mode`
# echo "LongCheer Incorporated" > /sys/class/android_usb/android0/iManufacturer
# echo "Android HSUSB modem phone" > /sys/class/android_usb/android0/iProduct
case "$usb_mode" in
    "")
    	setprop persist.sys.usb.mode D1
    	echo "" > /sys/class/android_usb/android0/iSerial
    ;;
    "D1") 
        echo "" > /sys/class/android_usb/android0/iSerial
    ;;#in usb D1 mode we does not want set serialno
    * )
        case "$serialno" in
            "")
                serialnum=`getprop ro.serialno`
                echo "$serialnum" > /sys/class/android_usb/android0/iSerial
            ;;
            * )
                echo "$serialno" > /sys/class/android_usb/android0/iSerial
            ;;
        esac
    ;;
esac

chown root.system /sys/devices/platform/msm_hsusb/gadget/wakeup
chmod 220 /sys/devices/platform/msm_hsusb/gadget/wakeup

#
# Allow persistent usb charging disabling
# User needs to set usb charging disabled in persist.usb.chgdisabled
#
target=`getprop ro.board.platform`
usbchgdisabled=`getprop persist.usb.chgdisabled`
case "$usbchgdisabled" in
    "") ;; #Do nothing here
    * )
    case $target in
        "msm8660")
        echo "$usbchgdisabled" > /sys/module/pmic8058_charger/parameters/disabled
        echo "$usbchgdisabled" > /sys/module/smb137b/parameters/disabled
	;;
        "msm8960")
        echo "$usbchgdisabled" > /sys/module/pm8921_charger/parameters/disabled
	;;
    esac
esac

usbcurrentlimit=`getprop persist.usb.currentlimit`
case "$usbcurrentlimit" in
    "") ;; #Do nothing here
    * )
    case $target in
        "msm8960")
        echo "$usbcurrentlimit" > /sys/module/pm8921_charger/parameters/usb_max_current
	;;
    esac
esac
#
# Allow USB enumeration with default PID/VID
#
# setprop sys.usb.config.extra diag
baseband=`getprop ro.baseband`
# echo 1  > /sys/class/android_usb/f_mass_storage/lun/nofua
usb_config=`getprop persist.sys.usb.config`
adb_enable=`getprop persist.service.adb.enable`
case "$usb_mode" in
	"D3") 
		case "$usb_config" in
			"mass_storage,file_storage,adb")
				case "$adb_enable" in
					"0")
						setprop persist.sys.usb.config mass_storage,file_storage
					;;
					* )
					;;
				esac
			;; #USB persist config is equal 'mass_storage,file_storage,adb', do nothing
			"mass_storage,file_storage")
#				case "$adb_enable" in
#					"0")
#					;;
#					* )
#						setprop persist.sys.usb.config mass_storage,file_storage,adb
#					;;
#				esac
			;; #USB persist config is equal 'mass_storage,file_storage', do nothing
			* ) #USB persist config not equal 'mass_storage,file_storage,adb', select default configuration 'mass_storage,file_storage,adb'
				case $target in
            		"msm8974")
                		setprop persist.sys.usb.config diag,adb
                		;;
            		"msm8960")
                		case "$baseband" in
                    		"mdm")
                         		setprop persist.sys.usb.config diag,diag_mdm,serial_hsic,serial_tty,rmnet_hsic,mass_storage,adb
                    		;;
                    		"sglte")
                         		setprop persist.sys.usb.config diag,diag_mdm,serial_smd,serial_tty,serial_hsuart,rmnet_hsuart,mass_storage,adb
                    		;;
                    		*)
                         		setprop persist.sys.usb.config diag,serial_smd,serial_tty,rmnet_bam,mass_storage,adb
                    		;;
                		esac
            		;;
            		"msm7627a" | "msm8625")
            			case "$adb_enable" in
							"0")
							    setprop persist.sys.usb.config mass_storage,file_storage
							;;
							* )
								setprop persist.sys.usb.config mass_storage,file_storage,adb
							;;
						esac
            		;;
            		* )
                		case "$baseband" in
                    		"svlte2a")
                         		setprop persist.sys.usb.config diag,diag_mdm,serial_sdio,serial_smd,rmnet_smd_sdio,mass_storage,adb
                    		;;
                    		"csfb")
                         		setprop persist.sys.usb.config diag,diag_mdm,serial_sdio,serial_tty,rmnet_sdio,mass_storage,adb
                    		;;
                    		*)
                         		setprop persist.sys.usb.config diag,serial_tty,serial_tty,rmnet_smd,mass_storage,adb
                    		;;
                		esac
            		;;
        		esac
			;;
		esac
	;; #in usb D3 mode we set the persist.sys.usb.config to mass_storage,file_storage,adb
	"D2")
		case "$usb_config" in
			"diag,serial_tty,serial_tty,mass_storage,file_storage,adb")
				case "$adb_enable" in
					"0")
						setprop persist.sys.usb.config diag,serial_tty,serial_tty,mass_storage,file_storage
					;;
					* )
					;;
				esac
			;; #USB persist config is equal 'diag,serial_tty,serial_tty,mass_storage,file_storage,adb', do nothing
			"diag,serial_tty,serial_tty,mass_storage,file_storage")
				case "$adb_enable" in
					"0")
					;;				
					* )
						setprop persist.sys.usb.config diag,serial_tty,serial_tty,mass_storage,file_storage,adb	
					;;
				esac
			;; #USB persist config is equal 'diag,serial_tty,serial_tty,mass_storage,file_storage', do nothing
			* ) #USB persist config not equal 'diag,serial_tty,serial_tty,mass_storage,adb', select default configuration 'diag,serial_tty,serial_tty,mass_storage,adb'
				case $target in
            		"msm8974")
                		setprop persist.sys.usb.config diag,adb
                	;;
            		"msm8960")
                		case "$baseband" in
                    		"mdm")
                         		setprop persist.sys.usb.config diag,diag_mdm,serial_hsic,serial_tty,rmnet_hsic,mass_storage,adb
                    		;;
                    		"sglte")
                         		setprop persist.sys.usb.config diag,diag_mdm,serial_smd,serial_tty,serial_hsuart,rmnet_hsuart,mass_storage,adb
                    		;;
                    		*)
                         		setprop persist.sys.usb.config diag,serial_smd,serial_tty,rmnet_bam,mass_storage,adb
                    		;;
                		esac
            		;;
            		"msm7627a" | "msm8625")
            			case "$adb_enable" in
							"0")
							    setprop persist.sys.usb.config diag,serial_tty,serial_tty,mass_storage,file_storage
							;;
							* )
							    setprop persist.sys.usb.config diag,serial_tty,serial_tty,mass_storage,file_storage,adb
						esac             		
            		;;
            		* )
                		case "$baseband" in
                    		"svlte2a")
                         		setprop persist.sys.usb.config diag,diag_mdm,serial_sdio,serial_smd,rmnet_smd_sdio,mass_storage,adb
                    		;;
                    		"csfb")
                         		setprop persist.sys.usb.config diag,diag_mdm,serial_sdio,serial_tty,rmnet_sdio,mass_storage,adb
                    		;;
                    		*)
                         		setprop persist.sys.usb.config diag,serial_tty,serial_tty,rmnet_smd,mass_storage,adb
                    		;;
                		esac
            		;;
        		esac
			;;
		esac
	;; #in usb D2 mode we set the persist.sys.usb.config to diag,serial_tty,serial_tty,mass_storage,file_storage,adb
	"D1")
		case "$usb_config" in
			"diag,serial_tty,serial_tty,mass_storage,adb")
#				case "$adb_enable" in
#					"0")
#						setprop persist.sys.usb.config diag,serial_tty,serial_tty,mass_storage					
#					;;
#					* )
						setprop persist.service.adb.enable 1
#					;;
#				esac
			;; #USB persist config is equal 'diag,serial_tty,serial_tty,mass_storage,adb', do nothing
			"diag,serial_tty,serial_tty,mass_storage")
				setprop persist.sys.usb.config diag,serial_tty,serial_tty,mass_storage,adb
#				case "$adb_enable" in
#					"0")
#					;;
#					* )
#						setprop persist.sys.usb.config diag,serial_tty,serial_tty,mass_storage,adb					
						setprop persist.service.adb.enable 1
#					;;
#				esac
			;; #USB persist config is equal 'diag,serial_tty,serial_tty,mass_storage', do nothing
			* ) #USB persist config not equal 'diag,serial_tty,serial_tty,mass_storage,adb', select default configuration 'diag,serial_tty,serial_tty,mass_storage,adb'
				case $target in
            		"msm8974")
                		setprop persist.sys.usb.config diag,adb
                	;;
            		"msm8960")
                		case "$baseband" in
                    		"mdm")
                         		setprop persist.sys.usb.config diag,diag_mdm,serial_hsic,serial_tty,rmnet_hsic,mass_storage,adb
                    		;;
                    		"sglte")
                         		setprop persist.sys.usb.config diag,diag_mdm,serial_smd,serial_tty,serial_hsuart,rmnet_hsuart,mass_storage,adb
                    		;;
                    		*)
                         		setprop persist.sys.usb.config diag,serial_smd,serial_tty,rmnet_bam,mass_storage,adb
                    		;;
                		esac
            		;;
            		"msm7627a" | "msm8625")
            			setprop persist.sys.usb.config diag,serial_tty,serial_tty,mass_storage,adb
#            			case "$adb_enable" in
#							"0")
#                				setprop persist.sys.usb.config diag,serial_tty,serial_tty,mass_storage
#							;;							
#							* )
#                				setprop persist.sys.usb.config diag,serial_tty,serial_tty,mass_storage,adb							
            					setprop persist.service.adb.enable 1
#							;;
#						esac
            		;;
            		* )
                		case "$baseband" in
                    		"svlte2a")
                         		setprop persist.sys.usb.config diag,diag_mdm,serial_sdio,serial_smd,rmnet_smd_sdio,mass_storage,adb
                    		;;
                    		"csfb")
                         		setprop persist.sys.usb.config diag,diag_mdm,serial_sdio,serial_tty,rmnet_sdio,mass_storage,adb
                    		;;
                    		*)
                         		setprop persist.sys.usb.config diag,serial_tty,serial_tty,rmnet_smd,mass_storage,adb
                    		;;
                		esac
            		;;
        		esac
			;;
		esac
	;; #in usb D1 mode we set the persist.sys.usb.config to diag,serial_tty,serial_tty,mass_storage,adb
esac

#
# Add support for exposing lun0 as cdrom in mass-storage
#
target=`getprop ro.product.device`
cdromname="/system/cdrom.iso"
cdromenable=`getprop persist.service.cdrom.enable`
usbdefconfig=`getprop persist.sys.usb.config`
case "$target" in
        "msm7627a" | "msm8625")
                case "$cdromenable" in
                        0)
                        		case "$usbdefconfig" in
                        				"mass_storage,file_storage,adb" | "mass_storage,file_storage")
                                				echo "" > /sys/class/android_usb/android0/f_file_storage/lun0/file
                                				;;
                                		"diag,serial_tty,serial_tty,mass_storage,file_storage,adb" | "diag,serial_tty,serial_tty,mass_storage,file_storage")
                                				echo "" > /sys/class/android_usb/android0/f_file_storage/lun0/file
                                				;;
                                		"mtp,diag,serial_tty,serial_tty,mass_storage,file_storage,adb" | "mtp,diag,serial_tty,serial_tty,mass_storage,file_storage")
                                				echo "" > /sys/class/android_usb/android0/f_file_storage/lun0/file
                                				;;
                                		"diag,serial_smd,serial_smd,mass_storage,file_storage,serial_tty,adb" | "diag,serial_smd,serial_smd,mass_storage,file_storage,serial_tty")
                                				echo "" > /sys/class/android_usb/android0/f_file_storage/lun0/file
                                				;;
                                		"mtp,diag,serial_smd,serial_smd,mass_storage,file_storage,serial_tty,adb" | "mtp,diag,serial_smd,serial_smd,mass_storage,file_storage,serial_tty")
                                				echo "" > /sys/class/android_usb/android0/f_file_storage/lun0/file
                                				;;		
                                				
                                		"mass_storage,adb" | "mass_storage")
                                				echo "" > /sys/class/android_usb/android0/f_mass_storage/lun0/file
                                				;;
                                		"diag,serial_tty,serial_tty,mass_storage,adb" | "diag,serial_tty,serial_tty,mass_storage")
                                				echo "" > /sys/class/android_usb/android0/f_mass_storage/lun0/file
                                				;;
                                		"mtp,diag,serial_tty,serial_tty,mass_storage,adb" | "mtp,diag,serial_tty,serial_tty,mass_storage")
                                				echo "" > /sys/class/android_usb/android0/f_mass_storage/lun0/file
                                				;;
                                		"diag,serial_smd,serial_smd,mass_storage,serial_tty,adb" | "diag,serial_smd,serial_smd,mass_storage,serial_tty")
                                				echo "" > /sys/class/android_usb/android0/f_mass_storage/lun0/file
                                				;;
                                		"mtp,diag,serial_smd,serial_smd,mass_storage,serial_tty,adb" | "mtp,diag,serial_smd,serial_smd,mass_storage,serial_tty")
                                				echo "" > /sys/class/android_usb/android0/f_mass_storage/lun0/file
                                				;;
                                		esac
                                ;;
                        1)
                                echo "mounting usbcdrom lun"
                                case "$usbdefconfig" in
                        				"mass_storage,file_storage,adb" | "mass_storage,file_storage")
                                				echo $cdromname > /sys/class/android_usb/android0/f_file_storage/lun0/file
                                				;;
                                		"diag,serial_tty,serial_tty,mass_storage,file_storage,adb" | "diag,serial_tty,serial_tty,mass_storage,file_storage")
                                				echo $cdromname > /sys/class/android_usb/android0/f_file_storage/lun0/file
                                				;;
                                		"mtp,diag,serial_tty,serial_tty,mass_storage,file_storage,adb" | "mtp,diag,serial_tty,serial_tty,mass_storage,file_storage")
                                				echo $cdromname > /sys/class/android_usb/android0/f_file_storage/lun0/file
                                				;;
                                		"diag,serial_smd,serial_smd,mass_storage,file_storage,serial_tty,adb" | "diag,serial_smd,serial_smd,mass_storage,file_storage,serial_tty")
                                				echo $cdromname > /sys/class/android_usb/android0/f_file_storage/lun0/file
                                				;;
                                		"mtp,diag,serial_smd,serial_smd,mass_storage,file_storage,serial_tty,adb" | "mtp,diag,serial_smd,serial_smd,mass_storage,file_storage,serial_tty")
                                				echo $cdromname > /sys/class/android_usb/android0/f_file_storage/lun0/file
                                				;;
                                		"mass_storage,adb" | "mass_storage")
                                				echo $cdromname > /sys/class/android_usb/android0/f_mass_storage/lun0/file
                                				;;
                                		"diag,serial_tty,serial_tty,mass_storage,adb" | "diag,serial_tty,serial_tty,mass_storage")
                                				echo $cdromname > /sys/class/android_usb/android0/f_mass_storage/lun0/file
                                				;;
                                		"mtp,diag,serial_tty,serial_tty,mass_storage,adb" | "mtp,diag,serial_tty,serial_tty,mass_storage")
                                				echo $cdromname > /sys/class/android_usb/android0/f_mass_storage/lun0/file
                                				;;
                                		"diag,serial_smd,serial_smd,mass_storage,serial_tty,adb" | "diag,serial_smd,serial_smd,mass_storage,serial_tty")
                                				echo $cdromname > /sys/class/android_usb/android0/f_mass_storage/lun0/file
                                				;;
                                		"mtp,diag,serial_smd,serial_smd,mass_storage,serial_tty,adb" | "mtp,diag,serial_smd,serial_smd,mass_storage,serial_tty")
                                				echo $cdromname > /sys/class/android_usb/android0/f_mass_storage/lun0/file
                                				;;
                                		esac
                                ;;
                esac
                ;;
esac

