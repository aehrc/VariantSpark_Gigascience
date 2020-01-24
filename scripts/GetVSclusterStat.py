import argparse
import boto3
import os
from os import path
import gzip
import re
import csv
import subprocess
import json
import sys

from GetRFstat import analyse_trees

# ###############
# Fetch VariantSpark statistics from clusters
# requires aws cli access
# e.g.
# python3 GetVSclusterStat.py --id "j-2QJ79Z2585CVC" --tmp ../log_temp --out ../
# creates a file ../j-2QJ79Z2585CVC.csv
# Step Name     ,sp ,sr  ,rn  ,rbs,rmt,rmtf,it ,...
# s-LPZIM24QLGR3,512,8100,1000,100,NA ,0.1 ,csv,...
#
# to fetch new results or from a different stepname do
# python3 GetVSclusterStat.py [..] --fetchNew --stepname E6steps
################


def fetchData(bucketName,bucketpath,clusterid,tempdir,stepname,fetchNew):
    """Fetch folder structure of steps from S3 and stores in tempdir"""
    if fetchNew==False and os.path.exists(tempdir+"/"+clusterid):
        print("file is already downloaded")
        return
    print("download S3://"+bucketName+"/"+bucketpath+clusterid+"/"+stepname, "to", tempdir)
    s3_resource = boto3.resource('s3')
    bucket = s3_resource.Bucket(bucketName)
    for object in bucket.objects.filter(Prefix = bucketpath+clusterid+"/"+stepname):
        if not os.path.exists(os.path.dirname(tempdir+"/"+object.key.strip(bucketpath))):
            os.makedirs(os.path.dirname(tempdir+"/"+object.key.strip(bucketpath)),exist_ok=True)
        if object.key.find(".gz")>-1: #only download .gz files (for fetchNew)
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
        for i in ["-sp ","-sr ","-rn ","-rbs ", "-rmt ", "-rmtf ", "-it ",
            "-if ","-fc ","-ff ","-of ","-on ","-om ","-omf ","-rmns ","-rmd ",
            "step "]:
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

def getVSoverlap(pheno,vsis):
    """Calculate and return the location of the truth SNPs from pheno in vsis"""

    if pheno==None or vsis==None:
        return ['NA']*2
    with open(pheno, newline='') as f:
        reader = csv.reader(f)
        row1 = next(reader)[3:8]  # gets the first line
    ar=[]
    for i in row1:
        stdot=subprocess.Popen("grep -wn "+i+" "+vsis, shell=True, stdout=subprocess.PIPE).stdout.read().decode('utf-8')
        try:
            ar.append(int(stdot.split(":")[0]))
        except:
            ar.append(-1)
    return ar


def extractNdownload(step,l,to,tmppath):
    """Parse out infos from controller and stdout"""

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
    """Calculate additional info (r1..Node Per Tree) and aggreate for each step"""

    print ("Downloading result files from S3 and processing them")
    for c in range(0,len(clusterinfo)):
        i=clusterinfo[c]
        sys.stdout.write('\r' + "step "+str(c)+" out of "+str(len(i)))
        sys.stdout.flush()
        ff=extractNdownload(i,10,6,tmppath)
        of=extractNdownload(i,11,6,tmppath)
        om=extractNdownload(i,13,6,tmppath)

        truthsVariables=getVSoverlap(ff,of)
        i.extend(truthsVariables)
        if om!=None:
            with open(om, 'r') as json_file:
                full_data = json.load(json_file)
            ar=analyse_trees(full_data['trees'],False)
            i.extend(ar)
        else:
            i.extend(['NA']*4)
        print("")
    return clusterinfo


def writeCSV(clusterinfoext, outfile):
    """write CSV"""

    outf=open(outfile+".csv","w")
    header=["Step Name","sp","sr","rn","rbs","rmt","rmtf","it","if","fc","ff",
        "of","on","om","omf","rmd","rmns","numSamples","numSnp","step",
        "load","tree","OOB","r1","r2","r3","r4","r5","Tree Depth",
        "Branch Depth","Leaves Per Tree","Node Per Tree"]
    outf.write(",".join(header)+"\n")
    for step in clusterinfoext:
        outf.write(",".join(str(i) for i in step)+"\n")

if __name__=="__main__":
    parser = argparse.ArgumentParser(description='Fetches from 3S the results and extracts info')
    parser.add_argument('--id', dest='clusterid', help='clusterid as appearing on S3', required=True)
    parser.add_argument('--tmp', dest='tempdir', help='tempdir to store results', default=".")
    parser.add_argument('--bucketname', dest='bucketname', help='bucketname', default="variant-spark")
    parser.add_argument('--bucketpath', dest='bucketpath', help='bucketpath', default="GigaScience/EMR-LOG/")
    parser.add_argument('--stepname', dest='stepname', help='name of step folder', default="steps")
    parser.add_argument('--out', dest='outprefix', help='output prefix', default=".")
    parser.add_argument('--fetchNew', dest='fetchNew', help='output prefix', action='store_true')

    args = parser.parse_args()

    # download the initial folder structure
    fetchData(args.bucketname, args.bucketpath, args.clusterid, args.tempdir,args.stepname,args.fetchNew)
    # parse the initial folder structure for infos (sp..OOB)
    clusterinfo=extractInfo(args.tempdir+"/"+args.clusterid+"/"+args.stepname)
    # append additional info that needs to be calculated (r1..Node Per Tree)
    clusterinfoext=calculateInfo(clusterinfo,args.tempdir+"/"+args.clusterid+"/"+args.stepname)
    # write to CSV
    writeCSV(clusterinfoext,args.outprefix+args.clusterid)
    print ("results in",args.outprefix+args.clusterid+".csv")
