# syntax=docker/dockerfile:experimental

FROM node:lts-stretch

ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

# Make sure SSH doesnt't prompt for host keys
RUN printf '%s\n' 'UserKnownHostsFile /dev/null' 'StrictHostKeyChecking no' \
    >> /etc/ssh/ssh_config

# Install node modules outside of application folder so it doesn't get hidden
# if we mount a local source over it.
RUN echo '--modules-folder /node_modules' > ~/.yarnrc
WORKDIR /app

# Copy only the packaging files so we can avoid breaking the cache with
# irrelevant changes
ONBUILD RUN \
  --mount=type=bind,source=./,target=/run/src \
  cd /run/src && \
  find . '(' \
    -name 'package.json' \
    -or -name 'package-lock.json' \
    -or -name 'yarn.lock' \
    -or -name '.npmrc' \
    -or -name '.yarnrc' \
  ')' -exec cp --parents '{}' /app ';'

# Set up the npmrc with only registry credentials if we have them, install all
# the packages. Ensure not to leave the secrets in the image.
ONBUILD RUN \
  --mount=type=cache,target=/root/.yarn/cache \
  --mount=type=secret,id=npmrc \
  --mount=type=ssh \
  grep -e 'registry=' -e 'authToken=' /run/secrets/npmrc > ~/.npmrc \
  && yarn install --non-interactive --frozen-lockfile \
  && chmod -R u=rwX,go=rX /node_modules \
  && rm ~/.npmrc

ONBUILD COPY ./ ./

# Make sure the node_modules from a mounted source does not break running
VOLUME ["/app/node_modules"]
