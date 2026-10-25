-- YAML under a dir with ansible.cfg is Ansible: ansiblels and ansible-lint attach to
-- yaml.ansible, while conform (yamlfmt) and treesitter fall back to its yaml part.
local function yaml(path)
  return vim.fs.root(path, "ansible.cfg") and "yaml.ansible" or "yaml"
end

vim.filetype.add({ extension = { yaml = yaml, yml = yaml } })
