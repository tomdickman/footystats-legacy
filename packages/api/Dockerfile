FROM public.ecr.aws/lambda/nodejs:16 as builder
WORKDIR /usr/app
COPY . .
RUN npm ci
RUN npm run prebuild
RUN npm run build

FROM public.ecr.aws/lambda/nodejs:16
WORKDIR ${LAMBDA_TASK_ROOT}
COPY --from=builder /usr/app/dist/* ./
CMD ["index.handler"]
