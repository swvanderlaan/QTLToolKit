from sys import argv
output_dir = argv[1]
region_file = argv[2]

chromosomes = []
variants = []

# with open('regions.txt', 'r') as file, open('variants.list', 'w') as var_file, open('chromosomes.list', 'w') as chr_file:
with open(region_file, 'r') as file, open(output_dir + '/variants.list', 'w') as var_file, open(output_dir + '/chromosomes.list', 'w') as chr_file:
    count = 0
    for line in file.readlines():
        line = line.strip('\n')
        line = line.split('\t')
        variants.append(line[0])
        print line
        if count == 0:
            var_file.write(line[0])
        if count != 0:
            var_file.write('\n' + line[0])
        if line[2] not in chromosomes:
            chromosomes.append(line[2])
            if count == 0:
                chr_file.write(line[2])
            if count != 0:
                chr_file.write('\n' + line[2])
        count += 1
print 'Number of chromosomes found: ' + str(len(chromosomes))
print 'Number of variants found: ' + str(len(variants))