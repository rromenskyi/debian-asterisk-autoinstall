#!/usr/bin/env python3
import sys
from asterisk.agi import *
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

agi = AGI()

try:
    if len(sys.argv) < 2:
        agi.verbose("No phone number provided")
        sys.exit(1)

    phone_number = sys.argv[1]
    valid, country, operator = validate_phone_number(phone_number)
    agi.set_variable('PHONE_VALID', int(valid))
    agi.set_variable('PHONE_COUNTRY', country)
    agi.set_variable('PHONE_OPERATOR', operator)
except AGIError as e:
    agi.verbose("AGI Error: %s" % str(e))
    sys.exit(1)
