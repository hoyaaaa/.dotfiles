export default {
    defaultBrowser: "Orion",
    handlers: [
        {
            match: ["github.com/*"],
            browser: "Orion - Work"
        },
        {
            match: (url) =>
                url.host === "identitycenter.amazonaws.com" ||
                url.host === "signin.aws.amazon.com" ||
                url.host.endsWith(".awsapps.com") ||
                (url.host.startsWith("device.sso.") && url.host.endsWith(".amazonaws.com")) ||
                (url.host.startsWith("oidc.") && url.host.endsWith(".amazonaws.com")),
            browser: "Orion - Work"
        },
    ]
}
