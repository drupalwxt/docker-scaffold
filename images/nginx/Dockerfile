ARG BASE_IMAGE
FROM $BASE_IMAGE as src

FROM nginx:alpine

COPY --from=src /var/www/html /var/www/html

# ------------------------
# SSH Server support
# Alpine Reference: https://docs.microsoft.com/en-us/azure/app-service/configure-custom-container?pivots=container-linux#enable-ssh
# This is a specfic feature of Azure Web Apps which has its own isolation and should not be used in any other scenario.
# ------------------------

# Install OpenSSH and set the password for root to "Docker!"
RUN apk add openssh \
     && echo "root:Docker!" | chpasswd

# Copy the sshd_config file to the /etc/ssh/ directory
COPY docker/conf/sshd/sshd_config /etc/ssh/

# Copy and configure the ssh_setup file
RUN mkdir -p /tmp
COPY docker/conf/sshd/ssh_setup.sh /tmp
RUN chmod +x /tmp/ssh_setup.sh \
    && (sleep 1;/tmp/ssh_setup.sh 2>&1 > /dev/null)

# Open port 2222 for SSH access
EXPOSE 80 2222
ENTRYPOINT ["docker/conf/sshd/sshd_init.sh"]
