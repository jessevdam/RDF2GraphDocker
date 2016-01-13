#!/bin/bash

set +e

usermod --uid ${USER_UID} galaxy
cd /
chown --from=1450 -fR ${USER_UID} ./

