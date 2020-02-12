# docker build -t hack .

FROM ubuntu as intermediate
RUN mkdir -p /data
RUN mkdir -p /result
# ADD unpacks the tarball automatically, you might not want that
COPY data.tar /data
RUN (cd /result; tar xf /data/data.tar)
# finally, /result ends up with the final data

FROM ubuntu
COPY --from=intermediate /result /result
# simply use the result
