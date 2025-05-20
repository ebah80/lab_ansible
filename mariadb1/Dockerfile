FROM almalinux:latest

# Install required tools
RUN dnf update -y && \
    dnf install -y python3 python3-pip tar wget sudo git iproute \
    gzip bzip2 xz unzip zstd libaio libaio-devel procps-ng openssh openssh-server && \
    pip3 install --upgrade pip && \
    pip3 install ansible

# Create ansible user and setup SSH access
RUN adduser ansible && \
    sed -i '/^ansible:/ s/:!/:*/' /etc/shadow  && \
    mkdir -p /home/ansible/.ssh && \
    chmod 700 /home/ansible/.ssh && \
    chown -R ansible:ansible /home/ansible/ && \
    ssh-keygen -A
COPY sshd_config /etc/ssh/

# Configure SUDOERS.D
COPY ../sudoers.d/ansible /etc/sudoers.d/ansible
RUN chmod 440 /etc/sudoers.d/ansible && \
    chown root:root /etc/sudoers.d/ansible

CMD ["sh", "-c", "/usr/sbin/sshd -D"]
