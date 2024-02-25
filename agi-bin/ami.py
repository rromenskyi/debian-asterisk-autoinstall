#!/usr/bin/env python3

import time
import asterisk.manager

def find_and_hangup(call_number):
    # Устанавливаем соединение с AMI
    manager = asterisk.manager.Manager()


    try:
        # Подключаемся к серверу Asterisk AMI
        manager.connect('176.74.220.11')
        manager.login('roman220ami', 'tiemo7eorievohBohk5ohjue')

        # Получаем список активных каналов
        response = manager.send_action({'Action': 'Command', 'Command': 'core show channels concise'})

        # Разбиваем строку ответа на строки итерацией по ним
        for line in response.data.splitlines():
            # Разделяем строку по пробелам
            parts = line.split('!')
            print(line)
            if len(parts) >= 10:
                # Получаем номер телефона из строки
                channel = parts[0]
                if call_number in line:
                    # Если найденный канал соответствует номеру, отправляем ему hangup
                    manager.send_action({'Action': 'Hangup', 'Channel': channel})
                    print(f"Hangup sent to {channel}")
                    break    
    except Exception as e:
        print("An error occurred:", e)
    finally:
        # Закрываем соединение
        manager.close()

if __name__ == "__main__":
    # Номер телефона, который вы хотите отбить
    target_number = '+34627412724'
    if target_number.startswith('+'):
        target_number = target_number.lstrip('+')
    find_and_hangup(target_number)
