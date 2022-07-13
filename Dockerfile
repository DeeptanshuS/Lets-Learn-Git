FROM lolhens/baseimage-openjre
ADD target/*jar springbootApp.jar
EXPOSE 8085
ENTRYPOINT ["java", "-jar", "springbootApp.jar"]
