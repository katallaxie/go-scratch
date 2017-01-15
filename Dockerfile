FROM scratch
ADD bin/httpd /
CMD ["/httpd"]
