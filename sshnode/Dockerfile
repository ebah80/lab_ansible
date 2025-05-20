# Use Alpine Linux as base image
FROM alpine:latest

# Install necessary packages
RUN apk add --no-cache \
    openrc \
    openssh \
    sudo \
    shadow \
    openssh-server-pam \
    openssh-server \
    python3 \
    curl

# Create ansible user and setup SSH access
RUN adduser -D ansible && \
    sed -i '/^ansible:/ s/:!/:*/' /etc/shadow  && \
    mkdir -p /home/ansible/.ssh && \
    chmod 700 /home/ansible/.ssh && \
    chown ansible:ansible /home/ansible/.ssh && \
    ssh-keygen -A

# Configure SUDOERS.D
COPY ../sudoers.d/ansible /etc/sudoers.d/ansible
RUN chmod 440 /etc/sudoers.d/ansible && \
    chown root:root /etc/sudoers.d/ansible

# Expose SSH port
# EXPOSE 22

# ENTRYPOINT ["/usr/sbin/sshd -D -e "$@""]
CMD ["sh", "-c", "/usr/sbin/sshd -D"]