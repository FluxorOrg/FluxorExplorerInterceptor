# FluxorExplorerInterceptor

An [Interceptor](https://github.com/FluxorOrg/Fluxor/blob/master/Sources/Fluxor/Interceptor.swift)  to register on a [Fluxor](https://github.com/FluxorOrg/Fluxor) [Store](https://github.com/FluxorOrg/Fluxor/blob/master/Sources/Fluxor/Store.swift). When registered it will send [FluxorExplorerSnapshots](https://github.com/FluxorOrg/FluxorExplorerSnapshot) to [FluxorExplorer](https://github.com/FluxorOrg/FluxorExplorer).

[![Swift version](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FFluxorOrg%2FFluxorExplorerInterceptor%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/FluxorOrg/FluxorExplorerInterceptor)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FFluxorOrg%2FFluxorExplorerInterceptor%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/FluxorOrg/FluxorExplorerInterceptor)

![Test](https://github.com/FluxorOrg/FluxorExplorerInterceptor/workflows/CI/badge.svg)
[![Maintainability](https://api.codeclimate.com/v1/badges/fe7eab769644c665f08a/maintainability)](https://codeclimate.com/github/FluxorOrg/FluxorExplorerInterceptor/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/fe7eab769644c665f08a/test_coverage)](https://codeclimate.com/github/FluxorOrg/FluxorExplorerInterceptor/test_coverage)
![Twitter](https://img.shields.io/badge/twitter-@mortengregersen-blue.svg?style=flat)

## ⚙️ Usage
For FluxorExplorer to receive all actions and state changes from an app, just register the `FluxorExplorerInterceptor` in the app's [Fluxor](https://github.com/FluxorOrg/Fluxor) `Store`. When [FluxorExplorer](https://github.com/FluxorOrg/FluxorExplorer) and the app are running on the same network (eg. running the app on the iOS Simulator), they will automatically connect and transmit data.

```swift
let store = Store(initialState: AppState())
#if DEBUG
store.register(interceptor: FluxorExplorerInterceptor(displayName: UIDevice.current.name))
#endif
```

**NOTE:** It is recommended to only register the interceptor in `DEBUG` builds.

### When developing with macOS App Sandbox
If the app is running on macOS and uses the App Sandbox, remember to enable the "Incoming Connections (Server)" and "Outgoing Connections (Client)", to be able to communicate with [FluxorExplorer](https://github.com/FluxorOrg/FluxorExplorer).
