#!/usr/bin/env python3

import sys

import json

import phonenumbers
from phonenumbers import geocoder, carrier

def validate_phone_number(phone_number):
    try:
        parsed_number = phonenumbers.parse(phone_number)
        valid = phonenumbers.is_valid_number(parsed_number)
        country = geocoder.description_for_number(parsed_number, 'en') if valid else 'Unknown'
        operator = carrier.name_for_number(parsed_number, 'en') if valid else 'Unknown'

        # Add the prefix "Mexico/" if the phone number starts with +52
        if valid and phone_number.startswith("+52"):
            country = "Mexico/" + country

        return valid, country, operator
    except phonenumbers.NumberParseException:
        return False, 'Unknown', 'Unknown'


def check_threshold(words, threshold):
    return len(words) >= threshold


def search_data_by_key(file_name, key):
    with open(file_name, "r") as file:
        data = json.load(file)

    if key in data:
        return data[key]
    else:
        return "Key not found"

def count_matching_arrays(array1, array2, threshold):
    set1 = set(array1)
    set2 = set(array2)

    intersection = set1.intersection(set2)

    if len(intersection) >= threshold and len(array1) >= threshold:
        return True
    else:
        return False

try:
    if len(sys.argv) < 2:
        print("No phone number provided")
        sys.exit(1)

    phone_number = sys.argv[1]
    valid, country, operator = validate_phone_number(phone_number)
    test_array = ['абонент','поза']

#    print (str(valid) + ' ' + country + '/' + operator)

    result = search_data_by_key("data.json", f"{country}/{operator}")

    if count_matching_arrays(result, test_array, 2):
        print('Answering machine detected')
    else:
        print('Answering machine not detected')

except Exception as e:
    print(f"An error occurred: {e}")
    sys.exit(1)