#!/bin/bash
docker build -t roman220/asterisk-certified:18.9-cert8-rc1 . &&
docker push roman220/asterisk-certified:18.9-cert8-rc1
