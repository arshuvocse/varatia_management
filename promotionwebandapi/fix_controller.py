import sys

filepath = 'Controllers/FieldOfficerController.cs'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

old_get = """    [HttpGet("/FieldForce/Products")]
    public IActionResult Products()
    {
        if (!IsFieldOfficer())
        {
            return RedirectToAction("Login", "Account");
        }

        return View("Products", new CompanyDistributionProductInputModel());
    }"""

new_get = """    [HttpGet("/FieldForce/Products")]
    public IActionResult Products([FromServices] ProductDistributionStore productStore)
    {
        if (!IsFieldOfficer()) return RedirectToAction("Login", "Account");

        var model = new FieldOfficerProductsViewModel
        {
            OfficerName = HttpContext.Session.GetString("UserName") ?? "ফিল্ড ফোর্স",
            Products = productStore.GetProducts(GetUserId())
        };
        return View("Products", model);
    }"""

old_post = """    [HttpPost("/FieldForce/Products")]
    [ValidateAntiForgeryToken]
    public IActionResult AddProduct([FromServices] ProductDistributionStore productStore, CompanyDistributionProductInputModel input)
    {
        if (!IsFieldOfficer())
        {
            return RedirectToAction("Login", "Account");
        }

        if (!ModelState.IsValid)
        {
            return View("Products", input);
        }

        try
        {
            productStore.CreateProduct(GetUserId(), input);
            TempData["SuccessMessage"] = "প্রোডাক্ট সফলভাবে এন্ট্রি করা হয়েছে।";
            return RedirectToAction(nameof(Products));
        }
        catch (Exception ex)
        {
            ModelState.AddModelError("", "প্রোডাক্ট এন্ট্রি করতে সমস্যা হয়েছে: " + ex.Message);
            return View("Products", input);
        }
    }"""

new_post = """    [HttpPost("/FieldForce/Products")]
    [ValidateAntiForgeryToken]
    public IActionResult AddProduct([FromServices] ProductDistributionStore productStore, FieldOfficerProductsViewModel model)
    {
        if (!IsFieldOfficer()) return RedirectToAction("Login", "Account");

        if (!ModelState.IsValid)
        {
            model.OfficerName = HttpContext.Session.GetString("UserName") ?? "ফিল্ড ফোর্স";
            model.Products = productStore.GetProducts(GetUserId());
            return View("Products", model);
        }

        try
        {
            productStore.CreateProduct(GetUserId(), model.Input);
            TempData["SuccessMessage"] = "প্রোডাক্ট সফলভাবে এন্ট্রি করা হয়েছে।";
            return RedirectToAction(nameof(Products));
        }
        catch (Exception ex)
        {
            ModelState.AddModelError("", "প্রোডাক্ট এন্ট্রি করতে সমস্যা হয়েছে: " + ex.Message);
            model.OfficerName = HttpContext.Session.GetString("UserName") ?? "ফিল্ড ফোর্স";
            model.Products = productStore.GetProducts(GetUserId());
            return View("Products", model);
        }
    }"""

content = content.replace(old_get, new_get)
content = content.replace(old_post, new_post)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
