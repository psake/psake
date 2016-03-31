You can set retry rules for a **task** exec function by using the **maxRetries** parameter.  For example, to have your **task** exec retry 3 times due to **any** unhandled exception:

```powershell
exec -maxRetries 3
```

You can also optionally specify a **task** exec to be retried only when a certain error message occurs using the **retryTriggerErrorPattern** parameter in conjunction with **maxRetries**:

```powershell
exec -maxRetries 3 -retryTriggerErrorPattern "Service is not currently available."
```

### Notes
1. psake will wait 1 second between retries.
1. The default for the maxRetries parameter if not specified is 0, i.e. the task will not be retried.