FROM postgres

RUN apt update

# Install Supervisord.
RUN apt install -y supervisor

# Install cron.
RUN apt install -y cron

# Install Python and PIP (version 3).
RUN apt install -y python3 python3-pip

# Get some dependencies before installing Duplicity via PIP3.
RUN apt install -y librsync-dev gettext

# Intall Duplicity via PIP3.
RUN pip3 install duplicity --break-system-packages

# Install B2 SDK.
RUN pip3 install b2sdk --break-system-packages

# Install Fasteners.
RUN pip3 install fasteners --break-system-packages

# Copy cron job.
COPY --chmod=0644 ./conf/cron.conf /etc/cron.d/backup

# Run crontab.
RUN crontab /etc/cron.d/backup

# Copy backup script.
COPY --chmod=0700 ./scripts/backup.sh /opt

CMD ["/usr/bin/supervisord"]