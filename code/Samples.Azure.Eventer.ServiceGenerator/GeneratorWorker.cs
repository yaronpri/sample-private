using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Azure;
using Azure.Storage;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Microsoft.ApplicationInsights;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Samples.Azure.Eventer.ServiceGenerator
{
    public class GeneratorWorker : BackgroundService
    {
        private static readonly string SAMPLE_FILE_1MB = "SampleSourceFile1MB.xml";        
        protected readonly IConfiguration Configuration;
        protected readonly ILogger<GeneratorWorker> Logger;
        protected readonly TelemetryClient TelemetryClient;        
        private BinaryData SampleFileData1MB;

        // Specify the StorageTransferOptions
        private BlobUploadOptions options = new BlobUploadOptions
        {             
            TransferOptions = new StorageTransferOptions
            {
                // Set the maximum number of workers that 
                // may be used in a parallel transfer.
                MaximumConcurrency = 16,

                // Set the maximum length of a transfer to 50MB.
                MaximumTransferSize = 50 * 1024 * 1024,                
            },
        };

        public GeneratorWorker(IConfiguration configuration, ILogger<GeneratorWorker> logger)
        {
            Configuration = configuration;
            Logger = logger;
        }

        public GeneratorWorker(IConfiguration configuration, ILogger<GeneratorWorker> logger, TelemetryClient tc) :
            this(configuration, logger)
        {
            TelemetryClient = tc;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            Logger.LogInformation("{0} started at: {1}", MyTelemetryInitializer.ROLE_NAME, DateTimeOffset.UtcNow);

            try
            {       
                //getting the blob container details which we should upload the generated files
                var sasToken = Configuration.GetValue<string>("BLOB_UPLOAD_SAS");
                var cred = new AzureSasCredential(sasToken);
                var blobUri = new Uri(Configuration.GetValue<string>("BLOB_UPLOAD_URI"));
                var containerName = Configuration.GetValue<string>("CONTAINER_NAME");
                var requested_req_per_sec = Configuration.GetValue<int>("REQUESTED_REQ_PER_SEC");
                var requested_simuator_time = Configuration.GetValue<int>("REQUESTED_SIMULATOR_TIME_IN_SEC");                

                var blobServiceClient = new BlobServiceClient(blobUri, cred);
                var containerClient = blobServiceClient.GetBlobContainerClient(containerName);

                var filebytes1MB = await File.ReadAllBytesAsync(SAMPLE_FILE_1MB);
                SampleFileData1MB = BinaryData.FromBytes(filebytes1MB);

                await SendFiles(containerClient, requested_req_per_sec, requested_simuator_time);                              
            }
            catch (Exception ex)
            {
                Logger.LogError("{0} - Error - {1} ", MyTelemetryInitializer.ROLE_NAME, ex.ToString());
            }
            Logger.LogInformation("{0} stop at: {1}", MyTelemetryInitializer.ROLE_NAME, DateTimeOffset.UtcNow);
        }

        private async Task SendFiles(BlobContainerClient containerClient, int requestedAmount, int requestedSeconds)
        {
            Logger.LogInformation("{0} - Start uploading files at: {1}", MyTelemetryInitializer.ROLE_NAME, DateTimeOffset.UtcNow);
            var totalTime = new TimeSpan();
            int numOfFiles = requestedAmount * requestedSeconds;
            var generatedNames = GenerateNames(numOfFiles);
            DateTime beforeStart = DateTime.Now;

            for (int i = 0; i < requestedSeconds; i++)
            {
                DateTime before = DateTime.Now;
                var tasks = new List<Task>();
                for (int j = 0; j < requestedAmount; j++)
                {
                    var index = (i * requestedAmount) + j;                    

                    using (Logger.BeginScope(new Dictionary<string, object> { ["fileuid"] = generatedNames[index], ["step"]="GeneratorUploadFile" }))
                    {
                        tasks.Add(UploadBlob(containerClient, generatedNames[index]));
                        Logger.LogInformation(MyTelemetryInitializer.ROLE_NAME + " sending - second " + (i + 1) + " of " + requestedSeconds + " total, upload: " + generatedNames[index]);
                    }
                }
                await Task.WhenAll(tasks);

                var after = DateTime.Now.Subtract(before);
                totalTime = totalTime.Add(after);
                //add the time need to wait for 1 second
                using (Logger.BeginScope(new Dictionary<string, object> { ["reqNumOfFiles"] = requestedAmount, ["reqTotalTime"] = after.TotalMilliseconds }))
                {
                    if (after.TotalMilliseconds < 1000)
                    {
                        await Task.Delay(TimeSpan.FromMilliseconds(1000 - after.TotalMilliseconds));
                        Logger.LogInformation(MyTelemetryInitializer.ROLE_NAME + " complete - second " + (i+1) + " of " + requestedSeconds + " total, number of files: " + requestedAmount + " took " + after.TotalMilliseconds + " ms");
                    }
                    else
                    {
                        Logger.LogWarning(MyTelemetryInitializer.ROLE_NAME + " co - second " + (i+1) + " of " + requestedSeconds + " total, number of files: " + requestedAmount + " took more than 1sec: " + after.TotalMilliseconds + " ms");
                    }
                }
            }
            using (Logger.BeginScope(new Dictionary<string, object> { ["totalNumOfFiles"] = requestedAmount * requestedSeconds, ["totalTime"] = totalTime.TotalMilliseconds, ["totalAvg"] = (totalTime.TotalMilliseconds / requestedSeconds) }))
            {
                Logger.LogInformation(MyTelemetryInitializer.ROLE_NAME + " sending - end uploading files at: " + DateTimeOffset.UtcNow + " took: " + DateTime.Now.Subtract(beforeStart).TotalMilliseconds + " ms " + " without delays: " + totalTime.TotalMilliseconds + " ms, avg of " + (totalTime.TotalMilliseconds / requestedSeconds) + " ms to upload " + requestedAmount + " files per 1sec");
            }        
        }
    
        private Task UploadBlob(BlobContainerClient containerClient, string filename)
        {
            var fullFilename = "demofile-" + filename + ".xml";
                        
            return containerClient.UploadBlobAsync(fullFilename, SampleFileData1MB);                        
        }

        private static List<string> GenerateNames(int count)
        {
            var retVal = new List<string>();

            for (int i = 0; i < count; i++)
            {
                retVal.Add(Guid.NewGuid().ToString().Replace("-",""));
            }

            return retVal;
        }

        private static byte[] Combine(byte[] first, byte[] second)
        {
            return first.Concat(second).ToArray();
        }
    }

    public class GeneratorDetails
    {
        public int RequestedAmount { get; set; }
        public int RequestedSeconds { get; set; }
    }    
}
