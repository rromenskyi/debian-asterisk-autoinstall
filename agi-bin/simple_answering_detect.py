#!/usr/bin/env python3
import sys
from asterisk.agi import *

agi = AGI()

# Количество вхождений слов из словаря в распознанный текст, для подтверждения, что это автоответчик
keywords_min=2

# Получаем значения переменных stt и sttscore из аргументов командной строки
stt = sys.argv[1].lower()  # переводим в нижний регистр
sttscore = sys.argv[2]

# Выводим полученные данные
agi.verbose(f"Received stt: {stt}")
agi.verbose(f"Received sttscore: {sttscore}")

# Определяем ключевые слова
autoinformer_keywords = ['абонент','связаться','ответить','автоответчик','абонента','недоступен']
# Проверяем уровень уверенности
if float(sttscore) < 60:  # Подставьте значение, которое вам подходит
    agi.set_variable('RESULT', 'repeat')

else:
    # Проверяем на наличие ключевых слов

    if sum(stt.lower().count(keyword) for keyword in autoinformer_keywords) >= keywords_min:
        agi.verbose('Autoinformer response detected')
        agi.set_variable('RESULT', 'recall')
    else:
        agi.verbose('No clear intent detected')
        agi.set_variable('RESULT', 'repeat')
