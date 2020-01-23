import argparse
import boto3
import os
from os import path
import gzip
import re
import csv
import subprocess
import json

from GetRFstat import analyse_trees


def fetchData(bucketName,bucketpath,clusterid,tempdir):
    """Fetches data from S3 and stores in tempdir"""
    if os.path.exists(tempdir+"/"+clusterid):
        print("file is already downloaded")
        return
    print("download S3://"+bucketName+"/"+bucketpath+clusterid+"/steps", "to", tempdir)
    s3_resource = boto3.resource('s3')
    bucket = s3_resource.Bucket(bucketName)
    for object in bucket.objects.filter(Prefix = bucketpath+clusterid+"/steps"):
        if not os.path.exists(os.path.dirname(tempdir+"/"+object.key.strip(bucketpath))):
            os.makedirs(os.path.dirname(tempdir+"/"+object.key.strip(bucketpath)))
        bucket.download_file(object.key,tempdir+"/"+object.key.strip(bucketpath))

def extractInfo(tmppath):
    """Parse out infos from controller and stdout"""
    clusterinfo=[]
    for step in os.listdir(tmppath):
        if(step.find(".")>-1):
            continue
        ############## Controller
        try:
            f=gzip.open(tmppath+"/"+step+"/controller.gz",'rb').read().decode('utf-8')
        except:
            print ("ERROR: file not found", tmppath+"/"+step+"/controller.gz")
            ar=[step,["NA"]*15]
            continue
        ar=[step]
        for i in ["-sp ","-sr ","-rn ","-rbs ", "-rmt ", "-rmtf ", "-it ","-if ","-fc ","-ff ","-of ","-on ","-om ","-omf ","step "]:
            try:
                ar.append(re.split('[ \']',f.split(i)[1])[0])
            except:
                ar.append("NA")
        #sample number and SNP number
        try:
            ff=ar[10].split(".")
            ar.extend([ff[1],ff[2]])
        except:
            ar.extend(["NA","NA"])
        ############## Stdout
        try:
            f=gzip.open(tmppath+"/"+step+"/stdout.gz",'rb').read().decode('utf-8')
        except:
            print ("ERROR: file not found", tmppath+"/"+step+"/controller.gz")
            ar=[step,["NA"]*15]
            continue
        t=f.split("took: ")
        try: #load runtime
            ar.append(t[1].split("\n")[0])
        except:
            ar.append("NA")
        try: # tree runtime
            ar.append(t[2].split(" ")[0])
        except:
            ar.append("NA")
        try: #OOB
            ar.append(f.split("oob accuracy: ")[1].split(",")[0])
        except:
            ar.append("NA")

        clusterinfo.append(ar)
    return clusterinfo

def getTopLine(pheno,vsis):
    with open(pheno, newline='') as f:
        reader = csv.reader(f)
        row1 = next(reader)[3:8]  # gets the first line
#        return ([ int(x.strip("v_")) for x in row1 ])
    ar=[]
    for i in row1:
        stdot=subprocess.Popen("grep -wn "+i+" "+vsis, shell=True, stdout=subprocess.PIPE).stdout.read().decode('utf-8')
        try:
            ar.append(int(stdot.split(":")[0]))
        except:
            ar.append(-1)
    return ar


def extractNdownload(step,l,to,tmppath):
    s3 = boto3.client('s3')
    ar=step[l].split("/")
    bucketName=ar[2]
    ffin="/".join(ar[3:to+1])
    ffout=tmppath+"/"+step[0]+"/"+ar[to]
    try:
        if (os.path.exists(ffout)==False):
            print("download",ffin,"to",ffout)
            s3.download_file(bucketName, ffin, ffout)
        return ffout
    except:
        print ("ERROR: S3 file not found ",ffin)
        return None

def calculateInfo(clusterinfo,tmppath):

    print ("Downloading result files from S3")
    for i in clusterinfo:
        ff=extractNdownload(i,10,6,tmppath)
        of=extractNdownload(i,11,6,tmppath)
        om=extractNdownload(i,13,6,tmppath)

        #truthsVariables=getTopLine(ff,of)
        #i.extend(truthsVariables)
        with open(om, 'r') as json_file:
            full_data = json.load(json_file)
        ar=analyse_trees(full_data['trees'],False)
        print (ar)


def writeCSV(outfile):
    outf=open(outfile+".csv","w")


if __name__=="__main__":
    parser = argparse.ArgumentParser(description='Fetches from 3S the results and extracts info')
    parser.add_argument('--id', dest='clusterid', help='clusterid as appearing on S3', required=True)
    parser.add_argument('--tmp', dest='tempdir', help='tempdir to store results', default=".")
    parser.add_argument('--bucketname', dest='bucketname', help='bucketname', default="variant-spark")
    parser.add_argument('--bucketpath', dest='bucketpath', help='bucketpath', default="GigaScience/EMR-LOG/")
    parser.add_argument('--out', dest='outprefix', help='output prefix', default=".")

    args = parser.parse_args()

    fetchData(args.bucketname, args.bucketpath, args.clusterid, args.tempdir)
    clusterinfo=extractInfo(args.tempdir+"/"+args.clusterid+"/steps")
    clusterinfoext=calculateInfo(clusterinfo,args.tempdir+"/"+args.clusterid+"/steps")
    #writeCSV(args.outprefix+args.clusterid)
    #print (clusterinfo)
