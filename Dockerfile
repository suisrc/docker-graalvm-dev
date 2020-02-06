# https://hub.docker.com/r/oracle/graalvm-ce/dockerfile
FROM oracle/graalvm-ce:19.3.1-java8
# args
ARG CODE_RELEASE
ARG FONT_URL
ARG FONT_RELEASE
ARG CODE_URL
ARG OH_MY_ZSH_SH_URL
ARG OH_MY_ZSH_SUGGES
ARG LINUX_MIRRORS
ARG MAVEN_RELEASE
ARG MAVEN_URL

# set version label
LABEL maintainer="suisrc@outlook.com"

ENV container docker
# linux and softs
# yum makecache && yum update -y &&\
RUN echo "**** update linux and install softs ****" && \
    yum install -y \
        sudo \
        curl \
        git \
        jq \
        net-tools \
        zsh \
        vim \
        p7zip \
        nano \
        fontconfig \
        ntpdate && \
    rm -rf /tmp/* /var/tmp/* 
    #rm -rf /var/cache/yum

# mvn
RUN echo "**** install maven ****" &&\
    if [ -z ${MAVEN_URL+x} ]; then \
        if [ -z ${MAVEN_RELEASE+x} ]; then \
            MAVEN_RELEASE="3.6.3"; \
        fi && \
        MAVEN_URL="http://mirrors.tuna.tsinghua.edu.cn/apache/maven/maven-3/${MAVEN_RELEASE}/binaries/apache-maven-${MAVEN_RELEASE}-bin.tar.gz"; \
    fi &&\
    mkdir -p /usr/share/maven &&\
    curl -L ${MAVEN_URL} -o /tmp/apache-maven.tar.gz &&\
    tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 &&\
    ln -s /usr/share/maven/bin/mvn /usr/bin/mvn &&\
    rm -rf /tmp/*

ENV MAVEN_HOME /usr/share/maven

# fonts
RUN echo "**** install sarasa-gothic fonts ****" && \
    if [ -z ${FONT_URL+x} ]; then \
        if [ -z ${FONT_RELEASE+x} ]; then \
            FONT_RELEASE=$(curl -sX GET "https://api.github.com/repos/suisrc/Sarasa-Gothic/releases/latest" \
            | awk '/tag_name/{print $4;exit}' FS='[""]'); \
        fi && \
        FONT_URL=$(curl -sX GET "https://api.github.com/repos/suisrc/Sarasa-Gothic/releases/tags/${FONT_RELEASE}" \
            | jq -r '.assets[] | select(.browser_download_url | contains("sc.7z")) | .browser_download_url'); \
    fi &&\
    curl -o /tmp/sarasa-gothic-ttf.7z -L "${FONT_URL}" && \
    mkdir -p /usr/share/fonts/truetype/sarasa-gothic &&\
    cd /usr/share/fonts/truetype/sarasa-gothic &&\
    7za x /tmp/sarasa-gothic-ttf.7z &&\
    fc-cache -f -v &&\
    rm -rf /tmp/*

# zsh
# https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh => https://gitee.com/mirrors/oh-my-zsh/raw/master/tools/install.sh
# https://github.com/zsh-users/zsh-autosuggestions => https://gitee.com/ncr/zsh-autosuggestions
RUN echo "**** install oh-my-zsh ****" && \
    if [ -z ${OH_MY_ZSH_SH_URL+x} ]; then \
        OH_MY_ZSH_SH_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"; \
    fi &&\
    if [ -z ${OH_MY_ZSH_SUGGES+x} ]; then \
        OH_MY_ZSH_SUGGES="https://github.com/zsh-users/zsh-autosuggestions"; \
    fi &&\
    sh -c "$(curl -fsSL ${OH_MY_ZSH_SH_URL})" &&\
    git clone "${OH_MY_ZSH_SUGGES}" /root/.oh-my-zsh/plugins/zsh-autosuggestions &&\
    echo "source ~/.oh-my-zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" >> /root/.zshrc &&\
    sed -i "s/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"agnoster\"/g" /root/.zshrc

# Code-Server
RUN echo "**** install code-server ****" && \
    if [ -z ${CODE_URL+x} ]; then \
        if [ -z ${CODE_RELEASE+x} ]; then \
            CODE_RELEASE=$(curl -sX GET "https://api.github.com/repos/cdr/code-server/releases/latest" \
            | awk '/tag_name/{print $4;exit}' FS='[""]'); \
        fi && \
        CODE_URL=$(curl -sX GET "https://api.github.com/repos/cdr/code-server/releases/tags/${CODE_RELEASE}" \
            | jq -r '.assets[] | select(.browser_download_url | contains("linux-x86_64")) | .browser_download_url'); \
    fi &&\
    curl -o /tmp/code.tar.gz -L "${CODE_URL}" && \
    tar xzf /tmp/code.tar.gz -C /usr/local/bin/ --strip-components=1 --wildcards code-server*/code-server && \
    rm -rf /tmp/*

# install code server extension
ENV SERVICE_URL=https://marketplace.visualstudio.com/_apis/public/gallery \
    ITEM_URL=https://marketplace.visualstudio.com/items \
    NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-bundle.crt

RUN echo "**** install code-server extension ****" && \
    code-server --install-extension ms-ceintl.vscode-language-pack-zh-hans &&\
    code-server --install-extension eamodio.gitlens && \
    code-server --install-extension mhutchie.git-graph &&\
    code-server --install-extension esbenp.prettier-vscode &&\
    code-server --install-extension redhat.vscode-yaml &&\
    code-server --install-extension redhat.vscode-xml &&\
    code-server --install-extension vscjava.vscode-java-pack &&\
    code-server --install-extension intellsmi.comment-translate

# config for user
COPY ["settings.json", "locale.json", "/root/.local/share/code-server/User/"]
ADD  "settings.xml" "/root/.m2/settings.xml"

# locale & language
# localectl set-locale LANG=zh_CN.UTF-8
# localectl set-locale LANG=zh_CN.UTF-8
#RUN yum install kde-l10n-Chinese -y &&\
#    sed -i "s/n_US.UTF-8/zh_CN.UTF-8/g" /etc/locale.conf
#ENV LANG="zh_CN.UTF-8" \
#    SHELL=/bin/zsh

COPY entrypoint.sh /usr/local/bin/

# worksapce
RUN mkdir -p /home/project
WORKDIR  /home/project
#VOLUME [ "/home/project" ]

# code-server start
EXPOSE 7778
ENTRYPOINT ["entrypoint.sh"]
CMD [ "code-server", "--host", "0.0.0.0", "--port", "7779", "--disable-telemetry", "--disable-updates", "/home/project"]


