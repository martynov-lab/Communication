FROM dart:2.18.2-sdk

WORKDIR /app

ADD . /app/
RUN dart pub get
RUN dart pub global activate conduit 3.2.10
EXPOSE 6200

ENTRYPOINT [ "dart","pub","run","conduit:conduit","serve","--port","6200" ]