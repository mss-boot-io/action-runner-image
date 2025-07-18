FROM debian:bookworm AS builder

# Install required system packages and dependencies
ADD ./install_packages /install_packages
RUN chmod +x /install_packages
RUN ./install_packages ca-certificates curl procps sudo unzip curl

# "Install" kubectl
RUN curl -L https://dl.k8s.io/release/v1.24.0/bin/linux/amd64/kubectl > /usr/bin/kubectl && \
    chmod +x /usr/bin/kubectl

# install the aws-iam-authenticator
RUN curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.15.10/2020-02-22/bin/linux/amd64/aws-iam-authenticator && \
    chmod +x ./aws-iam-authenticator && mv ./aws-iam-authenticator /usr/local/bin/

# Download Helm
RUN curl -L https://get.helm.sh/helm-v3.7.1-linux-amd64.tar.gz | tar -xz && \
    mv linux-amd64/helm /usr/local/bin/ && \
    rm -rf linux-amd64

# Install Argocd cli
RUN curl -L https://cd.apps.matrixlabs.org/download/argocd-linux-amd64  > /usr/bin/argocd && \
    chmod +x /usr/bin/argocd

FROM ghcr.io/actions-runner-controller/actions-runner-controller/actions-runner:latest

RUN sudo apt update -y && sudo apt-get install -y gettext && \
    sudo apt-get install -y apt-transport-https ca-certificates gnupg build-essential

COPY --from=builder /usr/local/bin/helm /usr/local/bin/
COPY --from=builder /usr/bin/kubectl /usr/local/bin/
COPY --from=builder /usr/local/bin/aws-iam-authenticator /usr/local/bin/
COPY --from=builder /usr/bin/argocd /usr/local/bin/
# install gcloud cli
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \ 
    sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
RUN sudo apt-get update && sudo apt-get install -y google-cloud-cli && sudo apt-get install -y vim

RUN /usr/local/bin/kubectl -h
RUN pip install awscli aws-sam-cli
RUN /usr/local/bin/aws-iam-authenticator -h
