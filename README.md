TEST

# 🚚 Workflows
![Build](https://img.shields.io/github/actions/workflow/status/connor-ricks/swift-workflows/checks.yaml?logo=GitHub)
![Codecov](https://img.shields.io/codecov/c/github/connor-ricks/swift-workflows?logo=Codecov&label=codecov)
![License](https://img.shields.io/github/license/connor-ricks/swift-workflows?color=blue)

Create reusable units of work by breaking down logic into workflows 
that can be composed together to make up complex business logic. 

## Overview

All applications have logic, some chunk of work that tackles a problem. As 
applications scale, oftentimes, developers find themselves needing to abstract
some piece of logic away from its original location in order to reuse that piece
of logic elsewhere.

Componentizing buisness logic is a powerful tool that allows developers to 
compose their logical complexities through a series of components, simplifying
usage, reducing code duplication and increasing testability of smaller units of
work.

Workflows is a tiny package that aims to provide an interface for creating,
composing and running these smaller components of buisness logic. 

## Usage

Learn how to create and run your workflows.

### Creating a workflow

Let's look at a fairly common example... Authenticating our user.


```swift
func authenticate(
    credentials: Credentials,
    authenticationService: AuthenticationService,
    userService: UserService,
    store: TokenStore,
    cache: Cache
) async throws -> User {
    let response = try await authenticationService.login(
        username: credentials.username,
        password: credentials.password
    )

    try await store.save(
        access: response.accessToken,
        refresh: response.refreshToken
    )

    let user = try await userService.user(for: response.id)
    try await cache.save(user: user)

    return user
}
```

This is a fairly simple function, but one could imagine a use-case in which 
there could be a quite a bit more logic involved. Even still, there is an
oppurtunity here to breakdown this work into multiple reusable workflows.

1. If out application was social, fetching a user given a `UUID` and caching 
the user locally is probably a piece of logic we would reuse beyond our login
logic. We would likely fetch and cache users whenever we view their profile.
This is a perfect candidate for a workflow.

```swift
struct GetUserWorkflow: Workflow {
    let id: UUID
    let service: UserService
    let cache: Cache

    func run() async throws -> User {
        if let user = try await cache.user(id: id) {
            return user
        } else {
            let user = try await service.user(for: id)
            try await cache.save(user: user)
            return user
        }
    }
}
```

2. The actual credential validation and saving is another opportunity to 
breakout. We may want to write tests for our authentication service and store
without having to write all the scaffolding for the user service, which could
likely be covered by its own tests.

```swift
struct AuthenticateWorkflow: Workflow {
    let credentials: Credentials
    let service: AuthenticationService
    let store: TokenStore

    func run() async throws -> AuthenticationResponse {
        let response = try await service.login(
            username: credentials.username,
            password: credentials.password
        )

        try await store.save(
            access: response.accessToken,
            refresh: response.refreshToken
        )

        return response
    }
} 
```

Now that we have two reusable workflows, we can compose these workflows 
together into a workflow that represents the initial function we wanted to 
write.

```swift
struct LoginWorkflow: Workflow {
    let credentials: Credentials
    let authenticationService: AuthenticationService
    let userService: UserService
    let store: TokenStore
    let cache: Cache

    func run() async throws -> User {
        try await AuthenticateWorkflow(
            credentials: credentials,
            service: authenticationService,
            store: store
        )
        .flatMap { response in
            GetUserWorkflow(
                id: response.id,
                service: userService,
                cache: cache
            )
        }.run()
    }
}
```

Now, if we ever choose to change, or update our authentication logic or user
retrieval and caching logic, we likely won't have to update our `LoginWorkflow`.

### Workflow dependencies

In the example above, the `LoginWorkflow` contained a child workflow called
`GetUserWorkflow`. In that use-case, the `GetUserWorkflow` had a dependency
on the output of the `AuthenticationWorkflow`. In order to chain these workflows
successfully, passing one ouptut to the other, there are two approaches.

```swift
// 1. Simple swift syntax
let response = try await AuthenticateWorkflow(...).run()
let user = try await GetUserWorkflow(id: response.id, ...).run()
return user

// 2. Using a `flatMap` operation. 
try await AuthenticateWorkflow(...).flatMap { response in
    GetUserWorkflow(id: response.id, ...)
}
.run()
```

### `ZipWorkflow`

Sometimes we may have a few requests we want to fire off concurrently, waiting
on all of their responses. We can accomplish this with a `ZipWorkflow`

```swift
let (dogs, cats, fish) = try await ZipWorkflow(
    DogsWorkflow()
    CatsWorkflow()
    FishWorkflow()
).result()
``` 

The `result()` function will run the child workflows concurrently, returning
their output as a tuple. If any of the workflows fail, the first error will be
thrown, and remaining workflows will be cancelled.

If you'd rather not fail after the first error, you can make use of `run()`. The
`run()` function returns a tuple of `Result<Output, Error>` objects for the
child workflows.

```swift
let (dogsResult, catsResult, fishResult) = try await ZipWorkflow(
    DogsWorkflow()
    CatsWorkflow()
    FishWorkflow()
).run()
``` 

This can be useful if you want to refresh your data, but you don't mind if some
of the workflows fail.

### `SequenceWorkflow`

Similarly to `ZipWorkflow`, `SequenceWorkflow` takes a tuple of child workflows
to run. However, rather than running them concurrently, the workflows will be
run syncronously. This can be useful when interacting with stateful 
dependencies.

### `CachedWorkflow`

Sometimes, you don't want to perform an expensive block of work again and again.
`CacheWorkflow` allows you to specify a block of work to run. Once the workflow
has completed, it will cache the result for subsequent runs, and return the
output.

### `AnyWorkflow`

When creating APIs, it can be helpful to abstract the inner workings and 
complexities away from consumers, preventing breaking changes and removing
unnecessary information.

You can use `AnyWorkflow` to erase an underlying workflow type.

```swift
// 1. Using the initializer.
let workflow = AnyWorkflow(DogsWorkflow())

// 2. Using the computed property.
let workflow = DogsWorkflow.eraseToAnyWorkflow()
```
