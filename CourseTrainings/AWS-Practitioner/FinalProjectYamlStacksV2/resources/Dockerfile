FROM public.ecr.aws/amazonlinux/amazonlinux:latest

#install updates and httpd for web server.
Run yum update -y && yum install httpd -y

#create the html file
Run mkdir -p '/var/www/html'
COPY index.html /var/www/html/index.html
COPY architecture-diagram.png /var/www/html/architecture-diagram.png

#configure the apache
        #add the creation command of  httpd folder in /var/run(required for apache) to the apache script that will be executed by docker.
Run echo 'mkdir -p /var/run/httpd' >> /root/run.apache.sh
        #add the creation command of httpd in /var/lock(required folder for apache) which will be executed by docker
Run echo 'mkdir -p /var/lock/httpd' >> /root/run.apacha.sh
        #add the -D Foreground to make apache to not run in the background and make it the main service on the docker image.
Run echo '/usr/sbin/httpd -D FOREGROUND' >> /root/run.apache.sh
        #give permissions to the run.apache.sh script to be executable
Run chmod 755 /root/run.apache.sh

#tells the container to listen to a specific port in this case 80(This doesn't actually publish the port, run docker -p 80:80 does)
EXPOSE 80

#tells the docker that the default command to execute at start is run.apache.sh script
CMD /root/run.apache.sh
