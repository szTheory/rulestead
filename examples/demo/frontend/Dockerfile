FROM node:22-alpine AS deps
WORKDIR /app

ARG NEXT_PUBLIC_FLAGS_API_BASE=http://localhost:4000
ARG NEXT_PUBLIC_FLAGS_ENVIRONMENT_KEY=staging
ARG NEXT_PUBLIC_FLAGS_TARGETING_KEY=demo-user

COPY examples/demo/frontend/package.json ./package.json
RUN npm install

FROM node:22-alpine AS builder
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY examples/demo/frontend ./

ARG NEXT_PUBLIC_FLAGS_API_BASE=http://localhost:4000
ARG NEXT_PUBLIC_FLAGS_ENVIRONMENT_KEY=staging
ARG NEXT_PUBLIC_FLAGS_TARGETING_KEY=demo-user

ENV NODE_ENV=production
ENV NEXT_PUBLIC_FLAGS_API_BASE=${NEXT_PUBLIC_FLAGS_API_BASE}
ENV NEXT_PUBLIC_FLAGS_ENVIRONMENT_KEY=${NEXT_PUBLIC_FLAGS_ENVIRONMENT_KEY}
ENV NEXT_PUBLIC_FLAGS_TARGETING_KEY=${NEXT_PUBLIC_FLAGS_TARGETING_KEY}
RUN npm run build

FROM node:22-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV HOSTNAME=0.0.0.0
ENV PORT=3000
ENV NEXT_PUBLIC_FLAGS_API_BASE=http://localhost:4000
ENV NEXT_PUBLIC_FLAGS_ENVIRONMENT_KEY=staging
ENV NEXT_PUBLIC_FLAGS_TARGETING_KEY=demo-user

COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/package.json ./package.json

EXPOSE 3000

CMD ["node", "server.js"]
