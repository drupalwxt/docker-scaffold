FROM solr:8.11.2-slim

# This is the default drupal core for solr. This can be repeated for multiple cores.
RUN /opt/solr/bin/solr start && \
    /opt/solr/bin/solr create_core -c drupal && \
    /opt/solr/bin/solr stop

# Copy over all the configuration for the drupal core
COPY conf/drupal_core/ /var/solr/data/drupal/conf