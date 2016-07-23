#!/bin/bash
tidy -utf8 -numeric -quiet -asxhtml --drop-proprietary-tags yes --force-output yes --doctype omit $1
