FROM centos:centos7

RUN yum update -y && \
    yum -y install sudo epel-release unzip && \
    yum install -y make-1:3.82-23.el7.x86_64 \
        python2-pip-0:8.1.2-6.el7.noarch \
        python-devel-2.7.5-69.el7_5.x86_64

RUN easy_install pip && pip install supervisor flask flask-jsonpify flask-sqlalchemy flask-restful

RUN pip install --trusted-host aws-cloudwatch.s3-website-us-east-1.amazonaws.com --extra-index-url=http://aws-cloudwatch.s3-website-us-east-1.amazonaws.com/ awscli-cwlogs==1.4.2

ADD root /

RUN mkdir -p /var/log/supervisord

EXPOSE 5002

CMD ["/opt/bin/run.sh"]
