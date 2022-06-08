FROM node:16

WORKDIR /app

COPY . .

RUN corepack enable
RUN yarn

EXPOSE 80

RUN yarn build

CMD ["yarn", "start"]