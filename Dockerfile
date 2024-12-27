FROM --platform=linux/amd64 gldeng/aelf-test-node:sha1514159 as father

# Use the specified base image
FROM --platform=linux/amd64 aelf/node:testnet-release-v1.12.3

RUN rm /app/appsettings.*
COPY --from=father /app/W1ptWN5n5mfdVvh3khTRm9KMJCAUdge9txNyVtyvZaYRYcqc1.json /root/.local/share/aelf/keys/W1ptWN5n5mfdVvh3khTRm9KMJCAUdge9txNyVtyvZaYRYcqc1.json
COPY --from=father /app/appsettings.json /app/
COPY --from=father /app/appsettings.MainChain.MainNet.json /app/
COPY --from=father /app/AElf.Blockchains* /app/
