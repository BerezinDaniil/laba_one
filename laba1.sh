#!/bin/bash

# "Нужно написать shell файл: 
# Который принимает на вход три параметра START|STOP|STATUS. 
# START запускает его в фоне и выдает PID процесса, 
# STATUS выдает состояние - запущен/нет, 
# STOP - останавливает PID
# Сам shell мониторит утилизацию дискового пространства, количество свободных inode. 
# Выводит информацию в виде csv файла. Имя файла должно содержать timestamp запуска 
# + дату за которую мониторинг. Предусмотреть создание нового файла при переходе через сутки
# "

PID_FILE_PATH="/tmp/monitor_disk.pid"
LOG_DIR="/tmp/monitor_disk_logs"
INTERVAL=10

mkdir -p "$LOG_DIR"

get_timestamp() { 
    date +"%Y-%m-%d_%H-%M-%S"
}

get_csv() { 
    date +"%Y-%m-%d.csv"
}

write_to_csv() {
    local filename="${LOG_DIR}/$(get_csv)"
    local timestamp=$(get_timestamp)

    if [[ ! -f "$filename" ]]; then
        echo "Timestamp,Filesystem,Size,Used,Available,Use%,Mounted_on,Inodes_Total,Inodes_Used,Inodes_Free,Inodes_Use%" > "$filename"
    fi

    df -k | tail -n +2 | while read -r filesystem size used avail capacity mounted_on; do
        inode_info=$(df -i "$mounted_on" | tail -n 1)
        inodes_total=$(echo "$inode_info" | awk '{print $2}')
        inodes_used=$(echo "$inode_info" | awk '{print $3}')
        inodes_free=$(echo "$inode_info" | awk '{print $4}')
        inode_use_percent=$(echo "$inode_info" | awk '{print $5}')
 
        echo "$timestamp,$filesystem,$((size / 1024)) MB,$((used / 1024)) MB,$((avail / 1024)) MB,$capacity,$mounted_on,$inodes_total,$inodes_used,$inodes_free,$inode_use_percent" >> "$filename"
    done
}

    # python3 inode_monitoring.py --filename ${FILENAME} --interval 10 --timestamp ${TIMESTAMP}

monitor_disk() {
    while true; do
        write_to_csv
        sleep "$INTERVAL"
    done
}

status() {
    if [[ -f "$PID_FILE_PATH" ]]; then
        PID=$(cat "$PID_FILE_PATH")
        if ps -p "$PID" > /dev/null; then
            echo "process is running with PID: $PID"
        else
            echo "process is not running"
        fi
    else
        echo "process is not running"
    fi
}

stop() {
    if [[ -f "$PID_FILE_PATH" ]]; then
        PID=$(cat "$PID_FILE_PATH")
        if ps -p "$PID" > /dev/null; then
            kill "$PID"
            echo "process with PID $PID stopped"
            rm -f "$PID_FILE_PATH"
        else
            echo "Процесс не найден"
            rm -f "$PID_FILE_PATH"
        fi
    else
        echo "process already started"
    fi
}

start() {
    if [[ -f "$PID_FILE_PATH" ]]; then
        echo "process already started with PID: $(cat "$PID_FILE_PATH")"
        exit 1
    fi

    monitor_disk &
    PID=$!
    echo "$PID" > "$PID_FILE_PATH"
    echo "process already started with PID: $PID"
}



case "$1" in
    START)
        start
        ;;
    STOP)
        stop
        ;;
    STATUS)
        status
        ;;
    *)
        echo "Использование: $0 {START|STOP|STATUS}"
        exit 1
        ;;
esac