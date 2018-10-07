#
# Docker container for analysis of suspicious documents with pre-installed forensic tools
#	Ready to be managed from python3 with official docker liblary
#
# Build:
#	docker build document-forensics-docker/ --rm -t "document-forensics-docker"
#
# Usage Shell:
# 	docker run --rm -it --security-opt="no-new-privileges" --cap-drop=all
#       	-v $(pwd):/home/malware
#       	--name python-test nshadov/malware-tools
#
# Usage Python:
#	import docker
#	client = docker.from_env()
#	container = client.containers.run(image='document-forensics-docker', user='malware', tty=True, stdin_open=True, detach=True)
#	print(container.exec_run(['peepdf','/home/malware/container_dest_file_name.tar',]).output.decode('utf-8'))
#	container.kill()

FROM python:2

LABEL maintainer="petermmm <p.matkovski@gmail.com>"

RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends apt-utils
RUN apt-get install -y sudo curl wget
RUN apt-get install -y yara
RUN apt-get install -y nano vim zsh curl git sudo
RUN apt-get install -y ghostscript
RUN apt-get install -y python-setuptools


RUN apt-get autoremove --purge -y
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN pip install pip --upgrade
RUN pip install oletools pdfparse pypdfparse peepdf hachoir-parser hachoir3 hachoir-core hachoir-metadata hachoir-urwid hachoir-subfile hachoir-regex


RUN useradd -m malware && \
  adduser malware sudo && \
  echo "malware:malware" | chpasswd
RUN chsh -s /bin/zsh malware

RUN git clone --recursive https://github.com/Rafiot/pdfid/ /home/malware/pdfid/
RUN chmod +x /home/malware/pdfid/pdfid/pdfid.py
RUN chown -R malware /usr/local/bin
RUN ln -s /home/malware/pdfid/pdfid/pdfid.py /usr/local/bin/pdfid

WORKDIR /home/malware


USER malware
ENV HOME /home/malware

CMD [ "/bin/bash" ]



# Configure Services and Port if needed
##COPY start.sh /start.sh
##CMD ["./start.sh"]

##EXPOSE 80 443



