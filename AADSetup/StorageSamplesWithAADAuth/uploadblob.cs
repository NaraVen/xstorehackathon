using System;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.Extensions.Logging;

namespace StorageSamplesWithAADAuth
{
    public static class uploadblob
    {
        [FunctionName("uploadblob")]
        public static void Run([TimerTrigger("0 */5 * * * *")]TimerInfo myTimer, ILogger log)
        {
            log.LogInformation($"C# Timer trigger upload blob function with AAD auth executed at: {DateTime.Now}");
        }
    }
}
