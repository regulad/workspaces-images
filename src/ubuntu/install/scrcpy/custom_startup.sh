#!/usr/bin/env bash
set -ex
#START_COMMAND="/usr/bin/supervisord"
DOCKER_PGREP="supervisord"
SCRCPY_PGREP="scrcpy"
#DEFAULT_ARGS="-n"
#ARGS=${APP_ARGS:-$DEFAULT_ARGS}
#ANDROID_VERSION=${ANDROID_VERSION:-"13.0.0"}
#REDROID_GPU_GUEST_MODE=${REDROID_GPU_GUEST_MODE:-"guest"}
SCRCPY_FPS=${SCRCPY_FPS:-"30"}
SCRCPY_WIDTH=${SCRCPY_WIDTH:-"720"}
SCRCPY_HEIGHT=${SCRCPY_HEIGHT:-"1280"}
#REDROID_DPI=${REDROID_DPI:-"320"}
SCRCPY_SHOW_CONSOLE=${SCRCPY_SHOW_CONSOLE:-"0"}
REDROID_DISABLE_AUTOSTART=${REDROID_DISABLE_AUTOSTART:-"0"}
REDROID_DISABLE_HOST_CHECKS=${REDROID_DISABLE_HOST_CHECKS:-"1"}
ADB_DEVICE=${ADB_DEVICE:-"localhost:5555"}

#ICON_ERROR="/usr/share/icons/ubuntu-mono-dark/status/22/system-devices-panel-alert.svg"


#LAUNCH_CONFIG='/dockerstartup/redroid_launch_selections.json'
## Launch Config Based Workflow
#if [ -e ${LAUNCH_CONFIG} ]; then
#  ANDROID_VERSION="$(jq -r '.android_version' ${LAUNCH_CONFIG})"
#fi


#function check_modules() {
#  if lsmod | grep -q binder_linux; then
#    echo "binder_linux module is loaded."
#  else
#      msg="Host level module binder_linux is not loaded. Cannot continue.\nSee https://github.com/remote-android/redroid-doc?tab=readme-ov-file#getting-started for more details."
#      echo msg
#      notify-send -u critical -t 0 -i "${ICON_ERROR}" "Redroid Error" "${msg}"
#      exit 1
#  fi
#}

function connect_adb() {
  echo "Attempting ADB connection..."
  adb connect "$ADB_DEVICE" | grep "connected"  # handles "connected to" and "already connected to"
}

start_android() {
#  sleep 5
#  xfce4-terminal --hide-menubar --command "bash -c \"sudo docker pull redroid/redroid:${ANDROID_VERSION}-latest \""
#  sudo docker run -itd --rm --privileged \
#    --pull always \
#    -v ~/data:/data \
#    -p 5555:5555 \
#    redroid/redroid:${ANDROID_VERSION}-latest \
#    androidboot.redroid_gpu_mode=${REDROID_GPU_GUEST_MODE} \
#    androidboot.redroid_fps=${SCRCPY_FPS} \
#    androidboot.redroid_width=${SCRCPY_WIDTH} \
#    androidboot.redroid_height=${SCRCPY_HEIGHT} \
#    androidboot.redroid_dpi=${REDROID_DPI}
    echo "Connecting to ADB device..."
    while ! connect_adb;
    do
      echo "Failed to connect to ADB device, retrying..."
      sleep 10
    done
    echo "Connected to ADB device."
}

start_scrcpy() {
  # https://github.com/Genymobile/scrcpy
  # https://gist.github.com/regulad/047f1bbe20614681a263caaa16dee661
  window_x=$(($SCRCPY_WIDTH / 2))
  window_y=$(($SCRCPY_HEIGHT / 2))
  scrcpy_command="scrcpy --audio-codec=aac -s \"$ADB_DEVICE\" --window-borderless --window-width=${SCRCPY_WIDTH} --window-height=${SCRCPY_HEIGHT} --window-x=${window_x} --window-y=${window_y} --shortcut-mod=lalt --print-fps --max-fps=${SCRCPY_FPS}"

  start_android  # Ensure that the device is connected, reconnect if necessary

  if [ "$SCRCPY_SHOW_CONSOLE" == "1" ]; then
    xfce4-terminal --hide-menubar --command "bash -c \"$scrcpy_command\"" &
  else
    eval "$scrcpy_command"
  fi

  wait_for_process $SCRCPY_PGREP
}

wait_for_process() {
  process_match=$1
  timeout=60
  interval=1
  elapsed_time=0

  echo "Waiting for $process_match..."
  while [[ $elapsed_time -lt $timeout ]]; do
      if pgrep -x $process_match > /dev/null; then
          echo "$process_match is running, continuing..."
          break
      fi
      sleep $interval
      elapsed_time=$((elapsed_time + interval))
  done

  if ! pgrep -x $process_match > /dev/null
  then
      echo "Did not find process $process_match"
  fi

}

kasm_startup() {
    if [ -n "$KASM_URL" ] ; then
        URL=$KASM_URL
    elif [ -z "$URL" ] ; then
        URL=$LAUNCH_URL
    fi

    if  [ -z "$DISABLE_CUSTOM_STARTUP" ] ||  [ -n "$FORCE" ]  ; then

        echo "Entering process startup loop"
        set +x
        while true
        do
            if ! pgrep -x $DOCKER_PGREP > /dev/null
            then
                set +e
                sudo /usr/bin/supervisord -n &
                set -e
                if [ "$REDROID_DISABLE_AUTOSTART" == "0" ]; then
                  start_android
                fi
            fi
            if [ "$REDROID_DISABLE_AUTOSTART" == "0" ]; then
                  if ! pgrep -x $SCRCPY_PGREP > /dev/null
                  then
                      start_scrcpy
                  fi
            fi
            sleep 1
        done
        set -x

    fi

}

/usr/bin/filter_ready
/usr/bin/desktop_ready


if [ "$REDROID_DISABLE_HOST_CHECKS" == "0" ]; then
  check_modules
fi
kasm_startup
