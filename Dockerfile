FROM python:slim-trixie

ARG USER_ID
ARG GROUP_ID

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    git \
    php-cli \
    php-xml \
    && rm -rf /var/lib/apt/lists/*

# wee need a older version of the setup tools which still provide pkg_resource
RUN pip3 install "setuptools<81"

RUN pip3 install --no-cache-dir transkribus-to-prima

RUN pip3 install --no-cache-dir ocrd_page_to_alto

RUN mkdir -p /var/www/html /var/www/config

RUN groupadd -g "${GROUP_ID}" appuser \
    && useradd -u "${USER_ID}" -g appuser -m -s /bin/bash appuser \
    && chown -R appuser:appuser /var/www/html

COPY --chown=appuser:appuser ./src/ /var/www/html/

# copy test data
COPY --chown=appuser:appuser ./tests/ /var/www/tests/
RUN chmod +x /var/www/tests/test-page-to-alto.sh

COPY ./config/php.ini /etc/php/8.4/cli/conf.d/99-custom-limits.ini

USER appuser

EXPOSE 8000

CMD ["php", "-S", "0.0.0.0:8000", "-t", "/var/www/html"]
