#!/bin/bash
#===============================================================================================#
#              FAIVELEY TRANSPORT               | No APS.....: D14203                           #
#          www.faiveleytransport.com            | Project....: DLC2ng                           #
#           Hall Parc - Batiment 6A             | Customer...: All                              #
#            3,rue du 19 mars 1962              | System.....: Door controller                  #
#         92230  Gennevilliers FRANCE           | Sub System.: Daughter board                   #
#===============================================================================================#
#    Date    | Name | Rev. | Comments                                                           #
#------------+------+------+--------------------------------------------------------------------#
# 04/05/2022 | STB  | A0   | First release                                                      #
#------------+------+------+--------------------------------------------------------------------#
#            |      |      |                                                                    #
#------------+------+------+--------------------------------------------------------------------#
#            |      |      |                                                                    #
#===============================================================================================#
export pidOfErrBlink=/tmp/ErrBlink.pid
export pidOfOkBlink=/tmp/OkBlink.pid
export errorLedDevice=/sys/class/gpio/PD0/value
export okLedDevice=/sys/class/gpio/PE7/value

# Import bash toolkit for btk_chmod_chown
source bash_toolkit.bash

#------------------------------------------------------------------------------
# Turn off OK LED
# OUT: stdout
#------------------------------------------------------------------------------
function set_ok_led_off() {
    if [ $PLATFORM_NAME == "DLCNext" ]
    then
        if [ -f $pidOfOkBlink ]
        then
            kill -9 $(cat $pidOfOkBlink)
            rm $pidOfOkBlink
        fi
        echo 0 > $okLedDevice
    fi
}

#------------------------------------------------------------------------------
# Turn on OK LED
# OUT: stdout
#------------------------------------------------------------------------------
function set_ok_led_on() {
    if [ $PLATFORM_NAME == "DLCNext" ]
    then
        if [ -f $pidOfOkBlink ]
        then
            kill -9 $(cat $pidOfOkBlink)
            rm $pidOfOkBlink
        fi
        echo 1 > $okLedDevice
    fi
}

function blink_ok_led_10hz_task() {
    if [ $PLATFORM_NAME == "DLCNext" ]
    then
        echo $BASHPID > $pidOfOkBlink
        btk_chmod_chown $pidOfOkBlink 666 root:root
        while [ 1 ]; do
            echo 1 > $okLedDevice
            sleep 0.05
            echo 0 > $okLedDevice
            sleep 0.05
        done
    fi
}

#------------------------------------------------------------------------------
# Turn on OK LED
# OUT: stdout
#------------------------------------------------------------------------------
function blink_ok_led_1hz() {
    blink_ok_led_1hz_task &
}

function blink_ok_led_1hz_task() {
    if [ $PLATFORM_NAME == "DLCNext" ]
    then
        echo $BASHPID > $pidOfOkBlink
        btk_chmod_chown $pidOfOkBlink 666 root:root
        while [ 1 ]; do
            echo 1 > $okLedDevice
            sleep 0.5
            echo 0 > $okLedDevice
            sleep 0.5
        done
    fi
}

#------------------------------------------------------------------------------
# Turn on OK LED
# OUT: stdout
#------------------------------------------------------------------------------
function blink_ok_led_10hz() {
    blink_ok_led_10hz_task &
}

function blink_ok_led_pulse_task() {
    if [ $PLATFORM_NAME == "DLCNext" ]
    then
        echo $BASHPID > $pidOfOkBlink
        btk_chmod_chown $pidOfOkBlink 666 root:root
        while [ 1 ]; do
            echo 1 > $okLedDevice
            sleep 0.05
            echo 0 > $okLedDevice
            sleep 0.95
        done
    fi
}

#------------------------------------------------------------------------------
# Turn on OK LED
# OUT: stdout
#------------------------------------------------------------------------------
function blink_ok_led_pulse() {
    blink_ok_led_pulse_task &
}

#------------------------------------------------------------------------------
# Turn off OK LED
# OUT: stdout
#------------------------------------------------------------------------------
function set_err_led_off() {
    if [ -f $pidOfErrBlink ]
    then
        kill -9 $(cat $pidOfErrBlink)
        rm $pidOfErrBlink
    fi
    echo 0 > $errorLedDevice
}

#------------------------------------------------------------------------------
# Turn on OK LED
# OUT: stdout
#------------------------------------------------------------------------------
function set_err_led_on() {
    if [ -f $pidOfErrBlink ]
    then
        kill -9 $(cat $pidOfErrBlink)
        rm $pidOfErrBlink
    fi
    echo 1 > $errorLedDevice
}

function blink_err_led_1hz_task() {
    echo $BASHPID > $pidOfErrBlink
    btk_chmod_chown $pidOfErrBlink 666 root:root
    while [ 1 ]; do
        echo 1 > $errorLedDevice
        sleep 0.5
        echo 0 > $errorLedDevice
        sleep 0.5
    done
}

#------------------------------------------------------------------------------
# Turn on OK LED
# OUT: stdout
#------------------------------------------------------------------------------
function blink_err_led_1hz() {
    if [ -f $pidOfErrBlink ]
    then
        kill -9 $(cat $pidOfErrBlink)
        rm $pidOfErrBlink
    fi
    blink_err_led_1hz_task &
}

function blink_err_led_10hz_task() {
    echo $BASHPID > $pidOfErrBlink
    btk_chmod_chown $pidOfErrBlink 666 root:root
    while [ 1 ]; do
        echo 1 > $errorLedDevice
        sleep 0.05
        echo 0 > $errorLedDevice
        sleep 0.05
    done
}

#------------------------------------------------------------------------------
# Turn on OK LED
# OUT: stdout
#------------------------------------------------------------------------------
function blink_err_led_10hz() {
    if [ -f $pidOfErrBlink ]
    then
        kill -9 $(cat $pidOfErrBlink)
        rm $pidOfErrBlink
    fi
    blink_err_led_10hz_task &
}
