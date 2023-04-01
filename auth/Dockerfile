FROM dart:2.19.2-sdk

WORKDIR /app

ADD . /app/
RUN dart pub get
RUN dart pub global activate conduit
EXPOSE 6100

ENTRYPOINT [ "dart","pub","run","conduit:conduit","serve","--port","6100" ] 