FROM ubuntu:jammy

# suppress interactive prompt for timezone when installing
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# fake init / runlevel so that services start properly after install
RUN echo exit 0 > /usr/sbin/policy-rc.d
ENV RUNLEVEL=1
