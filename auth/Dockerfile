FROM dart:2.18.6-sdk

WORKDIR /app

ADD . /app/
RUN dart pub get
RUN dart pub global activate conduit 4.1.6
EXPOSE 6100

ENTRYPOINT [ "dart","pub","run","conduit:conduit","serve","--port","6100" ] 