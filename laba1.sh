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

mkdir -p "$LOG_DIR"

get_timestamp() { 
    date +"%Y-%m-%d_%H-%M-%S"
}

get_csv() { 
    date +"%Y-%m-%d.csv"
}

write_to_csv() {
    TIMESTAMP=$(get_timestamp)
    FILENAME="${LOG_DIR}/$(get_csv)"
    python3 inode_monitoring.py --filename ${FILENAME} --interval 10 --timestamp ${TIMESTAMP}
}

status() {
    if [ -f "$PID_FILE_PATH" ]; then
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
    if [ -f "$PID_FILE_PATH" ]; then
        PID=$(cat "$PID_FILE_PATH")
        if ps -p "$PID" > /dev/null; then
            kill "$PID"
            echo "process with PID: $PID stopped"
            rm -f "$PID_FILE_PATH"
        else
            echo "process not found"
            rm -f "$PID_FILE_PATH"
        fi
    else
        echo "process doesn't run :("
    fi
}

start() {
    if [ -f "$PID_FILE_PATH" ]; then
        echo "process already started with PID: $(cat $PID_FILE_PATH)"
        exit 1
    fi

    write_to_csv &
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