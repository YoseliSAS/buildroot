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
# 19/09/2015 | STB  | A0   | First release                                                      #
#------------+------+------+--------------------------------------------------------------------#
#            |      |      |                                                                    #
#------------+------+------+--------------------------------------------------------------------#
#            |      |      |                                                                    #
#===============================================================================================#

#------------------------------------------------------------------------------
# Activate the buzzer
# $1 : beep time on duration in seconds
# $2 : beep time off duration in seconds
# $3 : beep count
# $4 : frequency
# OUT: stdout
#------------------------------------------------------------------------------
function btk_beep() {
    local -r _Ton=$1
    local -r _Toff=$2
    local -r _Count=$3
    local -r _FREQ=$4

    let "PER=1000000000/$_FREQ"
    let "DUTY=$PER/2"
    echo 0 > /sys/class/pwm_class/pwm4/enable
    echo $PER > /sys/class/pwm_class/pwm4/period
    echo $DUTY > /sys/class/pwm_class/pwm4/duty
    echo 1 > /sys/class/pwm_class/pwm4/enable

    for ((i=0 ; $_Count - $i ; i++))
    do
        echo 1 > /sys/class/pwm_class/pwm4/enable
        sleep $_Ton
        echo 0 > /sys/class/pwm_class/pwm4/enable
        sleep $_Toff
    done

    return $?
}
