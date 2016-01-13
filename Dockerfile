# RDF2Graph docker image

FROM bgruening/galaxy-stable

MAINTAINER Jesse van Dam, jesse.vandam@wur.nl

ENV GALAXY_CONFIG_BRAND=RDF2Graph \
GALAXY_CONFIG_WELCOME_URL=$GALAXY_CONFIG_DIR/web/static/Manual.html 

RUN apt-get update && \
apt-get install software-properties-common -y && \
add-apt-repository ppa:webupd8team/java -y && \
apt-get update && \
echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
apt-get install oracle-java8-installer -y && \
apt-get install oracle-java8-set-default && \
apt-get install -y xvfb maven html2text gedit && \
apt-get clean

USER galaxy

WORKDIR /home/galaxy

RUN mkdir Programs && \
wget -nc http://www.eu.apache.org/dist/jena/binaries/apache-jena-3.0.1.tar.gz && \
tar -kxvf ./apache-jena-3.0.1.tar.gz -C ./Programs/ &&  \
rm apache-jena-3.0.1.tar.gz && \
echo "export JENAROOT=/home/galaxy/Programs/apache-jena-3.0.1" >> ~/.bashrc && \
echo "PATH=\$JENAROOT/bin:\$PATH" >> ~/.bashrc && \
sed -i -e s/err/out/ /home/galaxy/Programs/apache-jena-3.0.1/jena-log4j.properties

RUN wget -nc http://chianti.ucsd.edu/cytoscape-3.2.0/Cytoscape_3_2_0_unix.sh && \
chmod +x ./Cytoscape_3_2_0_unix.sh &&  \
./Cytoscape_3_2_0_unix.sh -q -dir /home/galaxy/Programs/cytoscape && \
rm ./Cytoscape_3_2_0_unix.sh && \
echo "PATH=/home/galaxy/Programs/cytoscape:\$PATH" >> ~/.bashrc

WORKDIR /galaxy-central/tools
RUN git clone https://github.com/jessevdam/RDF2GraphGalaxy

WORKDIR /galaxy-central/tools/RDF2GraphGalaxy

RUN cp settings/tool_conf.xml ../../config/ && \
cp -r settings/static/ /etc/galaxy/web/static/ && \
cp settings/datatypes_conf.xml ../../config/ && \
cp settings/datatypes_conf.xml ../../config/datatypes_conf.xml.sample && \
cp settings/datatypes/*.py ../../lib/galaxy/datatypes/ && \
git submodule init && \
git submodule update

WORKDIR /galaxy-central/tools/RDF2GraphGalaxy/programs/RDF2Graph

RUN git clone https://github.com/jessevdam/RDFSimpleCon 
WORKDIR /galaxy-central/tools/RDF2GraphGalaxy/programs/RDF2Graph/RDFSimpleCon
RUN git checkout dev && \
mvn install
WORKDIR /galaxy-central/tools/RDF2GraphGalaxy/programs/RDF2Graph 
RUN mvn install && \
cp ./target/RDF2Graph-0.1-jar-with-dependencies.jar ./RDF2Graph.jar
WORKDIR /galaxy-central/tools/RDF2GraphGalaxy/programs/RDF2Graph/shexExporter
RUN npm install async commander jade lodash

ADD startXvfb.sh /home/galaxy/startXvfb.sh
RUN chmod +x /home/galaxy/.bashrc 

WORKDIR /home/galaxy/
RUN git clone https://github.com/jessevdam/RDF2GraphViewer 
WORKDIR /home/galaxy/RDF2GraphViewer
RUN mkdir -p /home/galaxy/CytoscapeConfiguration/3/apps/installed/
RUN mvn install

USER root

RUN chmod +x /home/galaxy/startXvfb.sh
RUN chown galaxy /home/galaxy/startXvfb.sh
RUN sed -i -e s/bin\\/bash$/bin\\/bash\\n\\/home\\/galaxy\\/\\startXvfb.sh/ /usr/bin/install-repository && \
ln -s /home/galaxy/Programs/apache-jena-3.0.1/bin/tdbquery /usr/bin/tdbquery && \   
ln -s /home/galaxy/Programs/apache-jena-3.0.1/bin/tdbloader /usr/bin/tdbloader && \   
ln -s /home/galaxy/Programs/apache-jena-3.0.1/bin/tdbupdate /usr/bin/tdbupdate && \   
ln -s /home/galaxy/Programs/apache-jena-3.0.1/bin/tdbdump /usr/bin/tdbdump && \ 
ln -s /home/galaxy/Programs/cytoscape/Cytoscape /usr/bin/Cytoscape    

ADD entrypoint.sh /sbin/entrypoint.sh
RUN sed -i -e s/bin\\/bash$/bin\\/bash\\n\\/sbin\\/entrypoint.sh/ /usr/bin/startup && \
chmod 755 /sbin/entrypoint.sh






