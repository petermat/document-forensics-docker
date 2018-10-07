# Document Forensics Docker #

Docker container for analysis of suspicious documents. 

1. Build & Run Docker Container
1. Load suspicious file
1. Run forensic tools
1. Kill container

From Command Line or Python 2/3 Environment 


# Build Docker Image #

Build an image from a Dockerfile.

		docker build document-forensics-docker/ --rm -t "document-forensics-docker"


# Example Usage #

## Command Line Example ##

	docker run --rm -it --security-opt="no-new-privileges" --cap-drop=all
	       	-v $(pwd):/home/malware
	       	--name python-test nshadov/malware-tools

## Python Examples ##

Tested on Python 3.6

### Load local file to running container as tar file ### 

	import time, tarfile, docker
	client = docker.from_env()

Prepare file binary stream

	tar_stream = io.BytesIO()
	dest_archive_info = tarfile.TarInfo(name='container_dest_file_name.tar')
	container_tar_file = tarfile.TarFile(fileobj=tar_stream, mode='w')

	decoded = open('malware_filename.bin')
	dest_archive_info.size = len(decoded)
	dest_archive_info.mtime = time.time()
	dest_archive_info.mode = 0o444
	container_tar_file.addfile(dest_archive_info, io.BytesIO(decoded))
	container_tar_file.close()
	tar_stream.seek(0)

Run container & put file

	container = client.containers.run(image='malware-tools-docker2', user='malware', tty=True,
	                                                  stdin_open=True, detach=True)
	container.put_archive('/home/malware', tar_stream)

### Analyze file with installed tools ###

### mraptor ###

mraptor is a tool designed to detect most malicious VBA Macros using generic heuristics. Unlike antivirus engines, it does not rely on signatures.

	print(container.exec_run(['mraptor','/home/malware/container_dest_file_name.tar',]).output.decode('utf-8'))


### olevba ###

olevba is a script to parse OLE and OpenXML files such as MS Office documents (e.g. Word, Excel), to detect VBA Macros, extract their source code in clear text, and detect security-related patterns such as auto-executable macros, suspicious VBA keywords used by malware, anti-sandboxing and anti-virtualization techniques, and potential IOCs (IP addresses, URLs, executable filenames, etc). It also detects and decodes several common obfuscation methods including Hex encoding, StrReverse, Base64, Dridex, VBA expressions, and extracts IOCs from decoded strings.

	print(container.exec_run(['olevba','--decode','--reveal','/home/malware/container_dest_file_name.tar',]).output.decode('utf-8'))


### hachoir-subfile ### 

hachoir-subfile is a tool based on hachoir-parser to find subfiles in any binary stream.

	print(container.exec_run(['hachoir-subfile','/home/malware/container_dest_file_name.tar',]).output.decode('utf-8'))


### hachoir-metadata ###

hachoir-metadata extracts metadata from multimedia files: music, picture, video, but also archives. It supports most common file formats:

* Archives: bzip2, gzip, zip, tar
* Audio: MPEG audio (“MP3”), WAV, Sun/NeXT audio, Ogg/Vorbis (OGG), MIDI, AIFF, AIFC, Real audio (RA)
* Image: BMP, CUR, EMF, ICO, GIF, JPEG, PCX, PNG, TGA, TIFF, WMF, XCF
* Misc: Torrent
* Program: EXE
* Video: ASF format (WMV video), AVI, Matroska (MKV), Quicktime (MOV), Ogg/Theora, Real media (RM)

	print(container.exec_run(['hachoir-metadata','/home/malware/container_dest_file_name.tar',]).output.decode('utf-8'))


### peepdf ###

peepdf is a Python tool to explore PDF files in order to find out if the file can be harmful or not. The aim of this tool is to provide all the necessary components that a security researcher could need in a PDF analysis without using 3 or 4 tools to make all the tasks. With peepdf it's possible to see all the objects in the document showing the suspicious elements, supports all the most used filters and encodings, it can parse different versions of a file, object streams and encrypted files. With the installation of PyV8 and Pylibemu it provides Javascript and shellcode analysis wrappers too. 

	print(container.exec_run(['peepdf','-f','/home/malware/container_dest_file_name.tar']).output.decode('utf-8'))


### pdfid ###

This tool will scan a file to look for certain PDF keywords, allowing you to identify PDF documents that contain (for example) JavaScript or execute an action when opened. PDFiD will also handle name obfuscation.

	print(container.exec_run(['pdfid','/home/malware/container_dest_file_name.tar',]).output.decode('utf-8'))


### ghostscript ###

create image preview

	print(container.exec_run(['ghostscript', '-dNOPAUSE', '-dBATCH', '-sDEVICE=pngalpha', '-r96',
								'-sOutputFile=out1.png','/home/malware/container_dest_file_name.tar'
								]))


Example python script:

	import docker
	client = docker.from_env()
	container = client.containers.run(image='document-forensics-docker', user='malware', tty=True, stdin_open=True, detach=True)
	print(container.exec_run(['peepdf','/home/malware/container_dest_file_name.tar',]).output.decode('utf-8'))
	container.kill()


### Privileged Mode  ###

If elevated privileges are needed, run options '--security-opt="no-new-privileges" --cap-drop=all' and user changed to 'malware' are done for your own safety -- you're operating on untrusted code. If you remove them you will be able to use sudo (same password as user name).