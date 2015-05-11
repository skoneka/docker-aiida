FROM phusion/baseimage:0.9.16



# Regenerate SSH host keys. baseimage-docker does not contain any, so you
# have to do that yourself. You may also comment out this instruction; the
# init system will auto-generate one during boot.
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

RUN apt-get update && apt-get install -y git python-pip ipython python2.7-dev libsqlite3-dev postgresql-server-dev-9.3  postgresql-9.3 
RUN cd /opt && ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa \
&& git clone http://bitbucket.org/aiida_team/aiida_core.git /opt/aiida \
&& cd /opt/aiida && pip install -r requirements.txt \
&& useradd aiida && mkdir /home/aiida && chown aiida.aiida /home/aiida \
&& echo "export PYTHONPATH=/opt/aiida:${PYTHONPATH}; export PATH=/opt/aiida/bin:${PATH}" >> /root/.bashrc \
&& echo "export PYTHONPATH=/opt/aiida:${PYTHONPATH}; export PATH=/opt/aiida/bin:${PATH}" >> /home/aiida/.bashrc

USER postgres

#RUN service postgresql start && su - postgres -c \echo\ "CREATE USER aiida WITH PASSWORD 'aiida_password'\; | psql template1'

RUN /etc/init.d/postgresql start &&\
    psql --command "CREATE USER aiida WITH PASSWORD 'aiida_password';" &&\
    createdb -O aiida aiidadb &&\
    psql --command "GRANT ALL PRIVILEGES ON DATABASE aiidadb to aiida;"

USER root

RUN /etc/init.d/postgresql start &&\
bash -c 'source ~/.bashrc; export PYTHONPATH=/opt/aiida:${PYTHONPATH}; export PATH=/opt/aiida/bin:${PATH}; echo -e "UTC\naiida@localhost\npostgres\nlocalhost\n5432\naiidadb\naiida\naiida_password\n/home/aiida/.aiida/repository/\n" | verdi install' 


RUN bash -c 'mkdir /etc/service/aiida && echo -e "#!/bin/bash\nexport PYTHONPATH=/opt/aiida:${PYTHONPATH}; export PATH=/opt/aiida/bin:${PATH};service postgresql start && verdi daemon start && echo NOW run: verdi shell && tail -f /var/log/dmesg" > /etc/service/aiida/run && chmod a+x /etc/service/aiida/run'

#FOR NOW RUN AS ROOT "verdi shell"

#USER aiida
